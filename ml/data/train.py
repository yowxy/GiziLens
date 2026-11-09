"""Latih / validasi / ekspor model segmentasi GiziLens (YOLO-seg).

Contoh:
  pip install ultralytics
  python data/train.py --model yolo11n-seg.pt --epochs 100
  python data/train.py --val runs/segment/gizilens/weights/best.pt
  python data/train.py --export runs/segment/gizilens/weights/best.pt --format tflite
"""
import argparse
import json
from pathlib import Path

from ultralytics import YOLO


DEFAULT_DATA = Path(__file__).resolve().parent / "gizilens.yaml"


def data_path(value):
    """Resolve dataset YAML from the current directory or this script's folder."""
    path = Path(value)
    if path.exists():
        return str(path.resolve())
    script_relative = Path(__file__).resolve().parent / path
    if script_relative.exists():
        return str(script_relative.resolve())
    return value


def class_ids(max_prioritas):
    """id kelas dengan prioritas <= max_prioritas (id tetap, head model tetap memuat semua kelas)."""
    f = Path(__file__).resolve().parent / "classes.json"
    if not f.exists():
        f = Path("classes.json")
    cls = json.load(open(f, encoding="utf-8"))["classes"]
    return [c["id"] for c in cls if c["prioritas"] <= max_prioritas]


def train(a):
    model = YOLO(a.model)
    data = data_path(a.data)
    extra = {"classes": class_ids(a.prioritas)} if a.prioritas else {}
    model.train(
        **extra,
        data=data, epochs=a.epochs, imgsz=a.imgsz, batch=a.batch,
        project="runs/segment", name="gizilens", patience=30, seed=42,
        # Foto ompreng diambil dari atas -> rotasi & flip vertikal aman
        flipud=0.5, fliplr=0.5, degrees=15.0, scale=0.3, translate=0.1,
        # Variasi pencahayaan dapur
        hsv_h=0.015, hsv_s=0.5, hsv_v=0.4,
        mosaic=1.0, close_mosaic=10,
        # Ompreng & sekat membungkus makanan. Dengan overlap_mask=True mask ompreng/sekat jadi
        # 'berlubang' di bawah makanan, padahal luasnya dipakai untuk normalisasi.
        overlap_mask=False,
    )


def validate(a):
    m = YOLO(a.val)
    r = m.val(data=data_path(a.data), imgsz=a.imgsz,
              split="test" if a.test else "val")
    print(f"Box  mAP50: {r.box.map50:.3f} | mAP50-95: {r.box.map:.3f}")
    print(f"Mask mAP50: {r.seg.map50:.3f} | mAP50-95: {r.seg.map:.3f}")
    print("\nmAP50-95 mask per kelas (cari kelas terlemah):")
    for i, ap in zip(r.seg.ap_class_index, r.seg.maps[r.seg.ap_class_index]):
        print(f"  {m.names[int(i)]:22s} {ap:.3f}")


def export(a):
    m = YOLO(a.export)
    # tflite int8 butuh data kalibrasi dari yaml; ncnn alternatif untuk Android native
    m.export(format=a.format, imgsz=a.imgsz, int8=(a.format == "tflite"),
             data=data_path(a.data))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--data", default=str(DEFAULT_DATA))
    p.add_argument("--model", default="yolo11n-seg.pt")
    p.add_argument("--epochs", type=int, default=100)
    p.add_argument("--imgsz", type=int, default=640)
    p.add_argument("--batch", type=int, default=16)
    p.add_argument("--prioritas", type=int, choices=[1, 2, 3],
                   help="latih hanya kelas prioritas <= N (1=inti MBG). Kosong = semua kelas")
    p.add_argument("--val", help="path weights untuk validasi")
    p.add_argument("--test", action="store_true", help="validasi di split test")
    p.add_argument("--export", help="path weights untuk ekspor")
    p.add_argument("--format", default="tflite", choices=["tflite", "ncnn", "onnx"])
    a = p.parse_args()
    if a.export:
        export(a)
    elif a.val:
        validate(a)
    else:
        train(a)
