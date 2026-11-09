"""Inferensi Modul 1 -> keluaran untuk Modul 2 (estimasi gram).

Output per foto (JSON):
  - tiap komponen: kelas, kelompok, confidence, luas mask (px), luas ternormalisasi
    terhadap luas ompreng (area_norm). area_norm tidak bergantung jarak kamera.

  python infer.py foto.jpg --weights best.pt --save hasil.jpg
"""
import argparse
import json

import numpy as np
from ultralytics import YOLO

from pathlib import Path

with open(Path(__file__).resolve().parent / "classes.json", encoding="utf-8") as f:
    KELOMPOK = {c["name"]: c["kelompok"] for c in json.load(f)["classes"]}


def poly_area(xy: np.ndarray) -> float:
    """Luas poligon (shoelace) dalam piksel gambar asli."""
    x, y = xy[:, 0], xy[:, 1]
    return float(0.5 * abs(np.dot(x, np.roll(y, 1)) - np.dot(y, np.roll(x, 1))))


def analyze(weights: str, image: str, conf: float = 0.25, save: str | None = None):
    model = YOLO(weights)
    # sekat_ompreng tidak dipakai: dibuang saat prediksi, jadi tidak muncul di JSON maupun gambar --save
    ids = [i for i, n in model.names.items() if n != "sekat_ompreng"]
    r = model.predict(image, conf=conf, classes=ids, retina_masks=True, verbose=False)[0]
    if r.masks is None:
        return {"error": "tidak ada objek terdeteksi", "komponen": []}

    items = []
    for poly, cls, c in zip(r.masks.xy, r.boxes.cls.tolist(), r.boxes.conf.tolist()):
        if len(poly) < 3:
            continue
        name = model.names[int(cls)]
        items.append({"kelas": name, "kelompok": KELOMPOK.get(name, name),
                      "conf": round(c, 3), "area_px": poly_area(poly)})

    trays = [i for i in items if i["kelas"] == "ompreng"]
    if not trays:
        return {"error": "ompreng tidak terdeteksi, ulangi foto (lihat panduan sudut)",
                "komponen": items}
    tray_area = max(t["area_px"] for t in trays)

    komponen = []
    for i in items:
        if i["kelompok"] == "wadah":  # ompreng itu sendiri bukan makanan
            continue
        i["area_norm"] = round(i["area_px"] / tray_area, 4)
        i["area_px"] = round(i["area_px"], 1)
        komponen.append(i)

    if save:
        r.save(filename=save)
    return {"tray_area_px": round(tray_area, 1), "komponen": komponen}


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("image")
    p.add_argument("--weights", default="runs/segment/gizilens/weights/best.pt")
    p.add_argument("--conf", type=float, default=0.25)
    p.add_argument("--save")
    a = p.parse_args()
    print(json.dumps(analyze(a.weights, a.image, a.conf, a.save), indent=2, ensure_ascii=False))