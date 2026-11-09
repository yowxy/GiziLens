"""Gabungkan beberapa dataset Roboflow (format YOLOv11) jadi satu dataset GiziLens.

Langkah:
  1) Unzip tiap dataset ke folder sendiri, mis. raw/indo_food, raw/veg_fruit, raw/rice
  2) python merge_datasets.py init  raw/indo_food raw/veg_fruit raw/rice
        -> membuat mapping.yaml (nama kelas sumber -> kelas GiziLens)
  3) Edit mapping.yaml: isi kelas target, kosongkan ("") untuk kelas yang dibuang
  4) python merge_datasets.py merge raw/indo_food raw/veg_fruit raw/rice --task seg --out dataset
"""
import argparse
import difflib
import hashlib
import json
import re
import shutil
from collections import Counter, defaultdict
from pathlib import Path

import yaml

SPLITS = {"train": "train", "valid": "val", "val": "val", "test": "test"}
IMG_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


CLASSES_PATH = None  # diisi dari --classes


def find_classes(explicit=None):
    """Cari classes.json: --classes, folder kerja, folder script, folder induk script."""
    here = Path(__file__).resolve().parent
    cands = [Path(explicit)] if explicit else [
        Path.cwd() / "classes.json", here / "classes.json", here.parent / "classes.json"]
    for c in cands:
        if c.exists():
            return c
    raise SystemExit("classes.json tidak ditemukan. Taruh di folder script/folder kerja "
                     "atau pakai --classes path/ke/classes.json\nDicari di: "
                     + ", ".join(str(c) for c in cands))


def load_classes():
    with open(find_classes(CLASSES_PATH), encoding="utf-8") as f:
        return json.load(f)["classes"]


LEVEL = "fine"  # "fine" = 227 kelas detail | "kelompok" = 8 kelompok pangan (untuk dataset berlabel kasar)

KELOMPOK_ALIASES = {
    "buah": ["buah", "buah buahan", "fruit", "fruits"],
    "sayur": ["sayur", "sayuran", "vegetable", "vegetables", "veggie", "veggies"],
    "lauk_hewani": ["lauk hewani", "protein hewani", "hewani", "meat", "daging", "animal protein"],
    "lauk_nabati": ["lauk nabati", "protein nabati", "nabati", "plant protein"],
    "karbohidrat": ["karbohidrat", "karbo", "carb", "carbs", "staple", "makanan pokok"],
    "susu": ["susu", "milk", "dairy"],
    "wadah": ["wadah", "ompreng", "tray", "food tray", "plate", "piring"],
    "pelengkap": ["pelengkap", "side", "sides", "snack"],
}


def kelompok_names():
    out = []
    for c in load_classes():
        if c["kelompok"] not in out:
            out.append(c["kelompok"])
    return out


def target_names():
    if LEVEL == "kelompok":
        return kelompok_names()
    return [c["name"] for c in load_classes()]


def norm(s):
    return re.sub(r"[\s_\-]+", " ", s.strip().lower())


def alias_index():
    """nama/alias (dinormalisasi) -> nama kelas GiziLens."""
    idx = {}
    for c in load_classes():
        tgt = c["kelompok"] if LEVEL == "kelompok" else c["name"]
        for k in [c["name"]] + c.get("aliases", []):
            idx[norm(k)] = tgt
    if LEVEL == "kelompok":
        for kel, als in KELOMPOK_ALIASES.items():
            for k in als + [kel]:
                idx[norm(k)] = kel
    return idx


def source_names(ds: Path):
    with open(ds / "data.yaml", encoding="utf-8") as f:
        names = yaml.safe_load(f)["names"]
    if isinstance(names, dict):
        names = [names[k] for k in sorted(names)]
    return list(names)


def init_mapping(datasets, out="mapping.yaml"):
    idx = alias_index()
    mapping = {}
    for d in datasets:
        d = Path(d)
        mapping[d.name] = {n: idx.get(norm(n), "") for n in source_names(d)}
    with open(out, "w", encoding="utf-8") as f:
        f.write("# Isi dengan nama kelas GiziLens (lihat classes.json). Kosong = dibuang.\n")
        f.write("# Yang sudah terisi = dicocokkan otomatis lewat nama/alias. PERIKSA, jangan percaya buta.\n")
        yaml.safe_dump(mapping, f, allow_unicode=True, sort_keys=False)
    for k, v in mapping.items():
        kosong = [n for n, t in v.items() if not t]
        print(f"[{k}] {len(v)} kelas: {len(v) - len(kosong)} terpetakan otomatis, {len(kosong)} perlu diisi/dibuang")
        if kosong:
            print("   belum terpetakan:", ", ".join(kosong))
    print(f"-> {out} dibuat. Edit dulu sebelum merge.")


def convert_line(parts, new_id, task, stats):
    """Satu baris label YOLO -> baris baru sesuai task, atau None."""
    vals = parts[1:]
    if len(vals) == 4:  # bbox: cx cy w h
        if task == "detect":
            stats["box"] += 1
            return f"{new_id} " + " ".join(vals)
        stats["box_dibuang"] += 1  # seg butuh poligon
        return None
    if len(vals) >= 6 and len(vals) % 2 == 0:  # poligon
        if task == "seg":
            stats["poly"] += 1
            return f"{new_id} " + " ".join(vals)
        xs = [float(v) for v in vals[0::2]]
        ys = [float(v) for v in vals[1::2]]
        cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        w, h = max(xs) - min(xs), max(ys) - min(ys)
        stats["poly"] += 1
        return f"{new_id} {cx:.6f} {cy:.6f} {w:.6f} {h:.6f}"
    stats["baris_rusak"] += 1
    return None


def merge(datasets, mapping_path, task, out, repeat=None, clean=False, val_frac=0.0):
    repeat = repeat or {}
    targets = target_names()
    tid = {n: i for i, n in enumerate(targets)}
    fine2kel = {c["name"]: c["kelompok"] for c in load_classes()}
    with open(mapping_path, encoding="utf-8") as f:
        mapping = yaml.safe_load(f)

    out = Path(out)
    seen = set()
    stats = Counter()
    inst = defaultdict(Counter)  # split -> kelas -> jumlah
    per_ds = Counter()

    # --- validasi semua mapping DULU; kalau ada yang salah, tidak ada file yang ditulis ---
    remaps, errors = {}, []
    for d in datasets:
        d = Path(d)
        if d.name not in mapping:
            raise SystemExit(f"Dataset '{d.name}' tidak ada di {mapping_path}. "
                             f"Jalankan 'init' lagi dengan folder ini, atau pakai --mapping yang benar.")
        m = mapping[d.name]
        remap = {}
        for i, n in enumerate(source_names(d)):
            t = (m.get(n) or "").strip()
            if not t:
                continue
            if LEVEL == "kelompok" and t in fine2kel:
                t = fine2kel[t]  # kelas detail otomatis diciutkan ke kelompoknya
            if t not in tid:
                mirip = difflib.get_close_matches(t, targets, n=3, cutoff=0.5)
                errors.append(f"  {d.name}: '{n}' -> '{t}' bukan kelas GiziLens"
                              + (f" (mungkin maksudmu: {', '.join(mirip)})" if mirip else ""))
                continue
            remap[i] = tid[t]
        remaps[d.name] = remap
    if errors:
        raise SystemExit("Mapping tidak valid, TIDAK ADA file yang ditulis:\n" + "\n".join(errors)
                         + f"\nPerbaiki di {mapping_path}. Kosongkan ('') kalau kelas itu mau dibuang.")

    # --- folder output: jangan campur dengan sisa merge sebelumnya ---
    if out.exists() and any(out.iterdir()):
        if not clean:
            raise SystemExit(f"Folder '{out}' sudah berisi data (mungkin sisa merge yang gagal). "
                             f"Hapus manual atau jalankan lagi dengan --clean.")
        shutil.rmtree(out)

    for d in datasets:
        d = Path(d)
        remap = remaps[d.name]

        # dataset tanpa split val: ambil val_frac dari train, dikelompokkan per GAMBAR ASLI
        # (nama sebelum '.rf.') supaya versi augmentasi gambar yang sama tidak bocor ke train & val
        resplit = val_frac > 0 and not any((d / s).exists() for s in ("valid", "val"))
        for sp_src, sp in SPLITS.items():
            img_dir = d / sp_src / "images"
            if not img_dir.exists():
                continue
            for img in sorted(img_dir.iterdir()):
                if img.suffix.lower() not in IMG_EXT:
                    continue
                lbl = d / sp_src / "labels" / (img.stem + ".txt")
                if not lbl.exists():
                    stats["tanpa_label"] += 1
                    continue
                h = hashlib.md5(img.read_bytes()).hexdigest()
                if h in seen:
                    stats["duplikat"] += 1
                    continue
                lines = []
                for raw in lbl.read_text().splitlines():
                    p = raw.split()
                    if not p or int(float(p[0])) not in remap:
                        stats["instance_dibuang"] += 1 if p else 0
                        continue
                    new = convert_line(p, remap[int(float(p[0]))], task, stats)
                    if new:
                        lines.append(new)
                if not lines:
                    stats["gambar_kosong_dilewati"] += 1
                    continue
                seen.add(h)
                name = f"{d.name}__{img.stem}"
                sp_use = sp
                if resplit and sp == "train":
                    g = img.name.split(".rf.")[0]
                    if int(hashlib.md5(g.encode()).hexdigest(), 16) % 10000 < val_frac * 10000:
                        sp_use = "val"
                (out / "images" / sp_use).mkdir(parents=True, exist_ok=True)
                (out / "labels" / sp_use).mkdir(parents=True, exist_ok=True)
                # --repeat nama_folder=N : gandakan gambar TRAIN dataset kecil (val/test tidak digandakan)
                n_copy = repeat.get(d.name, 1) if sp_use == "train" else 1
                for r in range(n_copy):
                    nm = name if r == 0 else f"{name}__rep{r}"
                    shutil.copy2(img, out / "images" / sp_use / (nm + img.suffix.lower()))
                    (out / "labels" / sp_use / (nm + ".txt")).write_text("\n".join(lines) + "\n")
                    per_ds[(d.name, sp_use)] += 1
                    for ln in lines:
                        inst[sp_use][targets[int(ln.split()[0])]] += 1

    cfg = {"path": str(out.resolve()), "train": "images/train", "val": "images/val",
           "test": "images/test", "names": dict(enumerate(targets))}
    with open(out / "gizilens.yaml", "w", encoding="utf-8") as f:
        yaml.safe_dump(cfg, f, allow_unicode=True, sort_keys=False)

    print("\n== Gambar per dataset/split ==")
    for (n, sp), c in sorted(per_ds.items()):
        print(f"  {n:20s} {sp:6s} {c}")
    print("\n== Instance per kelas (train | val) ==")
    for k in targets:
        c, v = inst["train"][k], inst["val"][k]
        flag = "  <-- SEDIKIT" if 0 < c < 100 else ("  <-- KOSONG" if c == 0 else "")
        if c >= 100 and v == 0:
            flag = "  <-- tidak ada di val"
        print(f"  {k:22s} {c:6d} | {v:5d}{flag}")
    print("\n== Catatan ==")
    for k, v in stats.items():
        print(f"  {k}: {v}")
    if stats["box_dibuang"]:
        print("  ! Ada label bbox yang dibuang karena task=seg. Pakai --task detect atau\n"
              "    ubah bbox jadi mask dulu (mis. SAM).")
    print(f"\nSelesai -> {out}/gizilens.yaml")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("cmd", choices=["init", "merge"])
    p.add_argument("datasets", nargs="+")
    p.add_argument("--mapping", default="mapping.yaml")
    p.add_argument("--task", choices=["seg", "detect"], default="seg")
    p.add_argument("--out", default="dataset")
    p.add_argument("--repeat", nargs="*", default=[], metavar="FOLDER=N",
                   help="gandakan gambar train dataset kecil, mis. --repeat ompreng_sendiri=4")
    p.add_argument("--val-frac", type=float, default=0.0, metavar="F",
                   help="untuk dataset TANPA split val: ambil sebagian F (mis. 0.1) dari train jadi val")
    p.add_argument("--clean", action="store_true", help="hapus folder --out lebih dulu kalau sudah ada isinya")
    p.add_argument("--classes", help="path classes.json (default: dicari otomatis)")
    p.add_argument("--level", choices=["fine", "kelompok"], default="fine",
                   help="fine = kelas detail; kelompok = 8 kelompok pangan (untuk dataset berlabel kasar)")
    a = p.parse_args()
    CLASSES_PATH = a.classes
    LEVEL = a.level
    if a.cmd == "init":
        init_mapping(a.datasets, a.mapping)
    else:
        merge(a.datasets, a.mapping, a.task, a.out,
              {k: int(v) for k, v in (x.split("=") for x in a.repeat)}, a.clean, a.val_frac)