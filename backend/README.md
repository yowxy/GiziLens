# GiziLens Detection API

Backend FastAPI untuk deteksi makanan ompreng. Semua logika deteksi (vision LLM
dan model ONNX lokal) dipindahkan dari aplikasi Flutter ke service ini, sehingga
aplikasi mobile cukup memanggil API. Ini menjadi fondasi sistem subscription.

## Struktur

```
backend/
├── app/
│   ├── main.py                 # FastAPI app + CORS
│   ├── config.py               # konfigurasi via .env
│   ├── schemas.py              # request/response Pydantic
│   ├── dependencies.py         # hook API key (subscription)
│   ├── routers/
│   │   ├── health.py           # GET /health
│   │   └── detection.py        # POST /api/v1/detect
│   └── services/
│       ├── llm_detector.py     # deteksi via vision LLM (SumoPod)
│       ├── onnx_detector.py    # deteksi via model ONNX (YOLO seg)
│       └── nutrition_catalog.py# katalog gizi (port dari Flutter)
├── models/                     # best.onnx + classes.json
├── requirements.txt
├── .env.example
└── Dockerfile
```

## Menjalankan

```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env             # isi SUMOPOD_API_KEY bila memakai engine llm
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Dokumentasi interaktif: http://localhost:8000/docs

## Endpoint

### `GET /health`

```json
{ "status": "ok", "engine": "llm", "llm_configured": true, "onnx_available": true }
```

### `POST /api/v1/detect`

`multipart/form-data`:

| Field | Tipe | Keterangan |
| --- | --- | --- |
| `image` | file | Gambar ompreng (wajib) |
| `engine` | string | `llm` \| `onnx` \| `auto` (default `auto`) |
| `target_group` | string | Nama kelompok AKG |
| `target_calories` | float | Target energi makan siang (kkal) |
| `target_protein` | float | Target protein (g) |
| `target_fat` | float | Target lemak (g) |
| `target_carbohydrate` | float | Target karbohidrat (g) |
| `target_fiber` | float | Target serat (g) |

Contoh:

```bash
curl -X POST http://localhost:8000/api/v1/detect \
  -F "image=@ompreng.jpg" \
  -F "engine=auto" \
  -F "target_group=SD Kelas 4 – 6 (10 – 12 Tahun)"
```

Respons:

```json
{
  "engine": "llm",
  "model": "gemini/gemini-3.5-flash",
  "items": [
    {
      "name": "Nasi Putih",
      "category": "Pokok",
      "estimated_gram": 150,
      "confidence": 0.95,
      "bbox": { "x": 0.1, "y": 0.2, "width": 0.4, "height": 0.3 },
      "nutrition": {
        "calories": 262.5, "protein": 4.8, "fat": 0.45,
        "carbohydrate": 60.9, "fiber": 0.6
      }
    }
  ],
  "summary": "...",
  "akg_assessment": "...",
  "processing_ms": 1830
}
```

## Engine

- **`llm`** — memanggil provider OpenAI-compatible (SumoPod). Butuh
  `SUMOPOD_API_KEY`. API key tidak lagi disimpan di aplikasi mobile.
- **`onnx`** — menjalankan `models/best.onnx` dengan onnxruntime. Tanpa biaya
  API, cocok untuk offline/volume tinggi.
- **`auto`** — mengikuti `DETECTION_ENGINE` di `.env`.

## Subscription (hook)

`app/dependencies.py::verify_api_key` sudah dipasang di endpoint deteksi. Set
`REQUIRE_API_KEY=true` dan isi `API_KEYS` (dipisah koma) untuk mengaktifkan
validasi. Nanti fungsi ini bisa diganti dengan lookup ke database subscription
(plan, kuota, masa aktif) tanpa mengubah endpoint.
