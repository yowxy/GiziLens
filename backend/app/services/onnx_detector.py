"""Local YOLO segmentation detection using onnxruntime.

Ported from the Flutter ``AiService``: the same 320x320 RGB input, confidence
threshold and output layout are used, then class names are mapped to the
nutrition catalog.
"""
from __future__ import annotations

import ast
import io
import json
import threading
from pathlib import Path

import numpy as np
from PIL import Image

from app.config import Settings
from app.schemas import BoundingBox, DetectionResponse, FoodItem, Nutrition
from app.services import nutrition_catalog


class OnnxError(RuntimeError):
    pass


class _OnnxModel:
    def __init__(self, model_path: Path, classes_path: Path, input_size: int) -> None:
        import onnxruntime as ort

        if not model_path.exists():
            raise OnnxError(f"Model ONNX tidak ditemukan: {model_path}")

        options = ort.SessionOptions()
        options.intra_op_num_threads = 2
        options.inter_op_num_threads = 1
        options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        self.session = ort.InferenceSession(
            str(model_path), sess_options=options, providers=["CPUExecutionProvider"]
        )
        self.input_name = self.session.get_inputs()[0].name
        self.input_size = input_size
        self.labels = self._load_labels(classes_path)

    def _load_labels(self, classes_path: Path) -> list[str]:
        """Prefer class names embedded in the model metadata (Ultralytics)."""
        metadata = self.session.get_modelmeta().custom_metadata_map
        raw_names = metadata.get("names")
        if raw_names:
            try:
                parsed = ast.literal_eval(raw_names)
                if isinstance(parsed, dict) and parsed:
                    return [str(parsed[key]) for key in sorted(parsed)]
            except (ValueError, SyntaxError):
                pass

        if not classes_path.exists():
            raise OnnxError(f"Daftar kelas tidak ditemukan: {classes_path}")
        with open(classes_path, encoding="utf-8") as handle:
            data = json.load(handle)
        return [c["name"] for c in data["classes"]]

    def preprocess(self, image_bytes: bytes) -> np.ndarray:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        image = image.resize((self.input_size, self.input_size), Image.BILINEAR)
        array = np.asarray(image, dtype=np.float32) / 255.0
        # HWC -> CHW, add batch dimension
        return np.transpose(array, (2, 0, 1))[None, ...]

    def run(self, image_bytes: bytes) -> np.ndarray:
        tensor = self.preprocess(image_bytes)
        return self.session.run(None, {self.input_name: tensor})[0]


_lock = threading.Lock()
_cache: dict[tuple[str, str, int], _OnnxModel] = {}


def _resolve_model_path(settings: Settings, value: str) -> Path:
    path = settings.resolve_path(value)
    if path.exists():
        return path
    # Fallback: the original asset location inside the Flutter project.
    fallback = settings.resolve_path(
        "../fe/gizi_lens/assets/ml/" + Path(value).name
    )
    return fallback if fallback.exists() else path


def _get_model(settings: Settings) -> _OnnxModel:
    model_path = _resolve_model_path(settings, settings.onnx_model_path)
    classes_path = _resolve_model_path(settings, settings.onnx_classes_path)
    key = (str(model_path), str(classes_path), settings.onnx_input_size)
    with _lock:
        model = _cache.get(key)
        if model is None:
            model = _OnnxModel(model_path, classes_path, settings.onnx_input_size)
            _cache[key] = model
        return model


def is_available(settings: Settings) -> bool:
    return _resolve_model_path(settings, settings.onnx_model_path).exists()


def _iou(box: np.ndarray, boxes: np.ndarray) -> np.ndarray:
    x1 = np.maximum(box[0], boxes[:, 0])
    y1 = np.maximum(box[1], boxes[:, 1])
    x2 = np.minimum(box[2], boxes[:, 2])
    y2 = np.minimum(box[3], boxes[:, 3])
    inter = np.clip(x2 - x1, 0, None) * np.clip(y2 - y1, 0, None)
    area_box = (box[2] - box[0]) * (box[3] - box[1])
    area_boxes = (boxes[:, 2] - boxes[:, 0]) * (boxes[:, 3] - boxes[:, 1])
    union = area_box + area_boxes - inter
    return np.where(union > 0, inter / union, 0.0)


def _nms(boxes: np.ndarray, scores: np.ndarray, iou_threshold: float) -> list[int]:
    order = scores.argsort()[::-1]
    kept: list[int] = []
    while order.size > 0:
        current = int(order[0])
        kept.append(current)
        if order.size == 1:
            break
        ious = _iou(boxes[current], boxes[order[1:]])
        order = order[1:][ious <= iou_threshold]
    return kept


def detect(settings: Settings, image_bytes: bytes) -> DetectionResponse:
    model = _get_model(settings)
    output = np.asarray(model.run(image_bytes))
    output = np.squeeze(output, axis=0)

    # Normalise to [channels, candidates]. YOLO export is [4+nc+masks, anchors].
    if output.ndim != 2:
        raise OnnxError(f"Bentuk output ONNX tidak dikenal: {output.shape}")
    if output.shape[0] > output.shape[1]:
        output = output.T

    channels = output.shape[0]
    class_count = min(len(model.labels), max(channels - 4, 0))
    if class_count <= 0:
        raise OnnxError("Output ONNX tidak memiliki kanal kelas.")

    scores = output[4 : 4 + class_count, :].T
    class_ids = scores.argmax(axis=1)
    confidences = scores.max(axis=1)

    mask = confidences >= settings.onnx_conf_threshold
    if not mask.any():
        return DetectionResponse(engine="onnx", model="best.onnx", items=[])

    centers = output[:4, :].T[mask]
    class_ids = class_ids[mask]
    confidences = confidences[mask]

    half = centers[:, 2:4] / 2
    boxes_xyxy = np.concatenate([centers[:, :2] - half, centers[:, :2] + half], axis=1)
    keep = _nms(boxes_xyxy, confidences, settings.onnx_iou_threshold)

    size = float(model.input_size)
    best_by_class: dict[int, tuple[float, np.ndarray]] = {}
    for index in keep:
        class_id = int(class_ids[index])
        confidence = float(confidences[index])
        current = best_by_class.get(class_id)
        if current is None or confidence > current[0]:
            best_by_class[class_id] = (confidence, boxes_xyxy[index])

    items: list[FoodItem] = []
    for class_id, (confidence, box) in sorted(
        best_by_class.items(), key=lambda pair: pair[1][0], reverse=True
    ):
        if class_id >= len(model.labels):
            continue
        profile = nutrition_catalog.lookup(model.labels[class_id])
        if profile is None:
            continue

        x1, y1, x2, y2 = box
        bbox = BoundingBox(
            x=float(min(max(x1 / size, 0.0), 1.0)),
            y=float(min(max(y1 / size, 0.0), 1.0)),
            width=float(min(max((x2 - x1) / size, 0.0), 1.0)),
            height=float(min(max((y2 - y1) / size, 0.0), 1.0)),
        )
        items.append(
            FoodItem(
                name=profile.display_name,
                category=profile.category,
                estimated_gram=profile.default_gram,
                confidence=round(confidence, 4),
                bbox=bbox,
                nutrition=Nutrition(**profile.totals()),
            )
        )
        if len(items) >= settings.onnx_max_items:
            break

    return DetectionResponse(engine="onnx", model="best.onnx", items=items)
