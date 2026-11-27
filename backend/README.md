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

## Database PostgreSQL

Firebase dipakai untuk **autentikasi**; PostgreSQL menyimpan seluruh data
operasional (organisasi, batch, scan, inspeksi, langganan, pembayaran, biaya AI).
Skema dikelola dengan **Alembic** di `app/database/migrations/`.

```bash
# 1. Buat database (sekali saja)
psql -U postgres -h localhost -c "CREATE DATABASE gizilens;"

# 2. Isi DATABASE_URL di .env
#    DATABASE_URL=postgresql+psycopg://postgres:<password>@localhost:5432/gizilens

# 3. Terapkan skema + seed paket & AKG
python scripts/init_db.py

# Hanya skema, tanpa seed:
python scripts/init_db.py --no-seed
```

`scripts/init_db.py` menjalankan `alembic upgrade head` lalu menerapkan
`app/database/migrations/seeds/*.sql`. Untuk kontrol manual:

```bash
cd app/database/migrations
alembic upgrade head      # revisi akhir: 0004 (head)
alembic current
alembic downgrade -1      # hati-hati: menghapus revisi terakhir
```

Struktur tabel (lihat `app/database/migrations/alembic/versions/sql/`):

| Revisi | Tabel |
| --- | --- |
| 0001 | `organizations`, `organization_members`, `sppg_school_links`, `batches`, `akg_targets` |
| 0002 | `plans`, `subscriptions`, `quota_buckets`, `payments` |
| 0003 | `scans`, `scan_images`, `inspections`, `inspection_items` |
| 0004 | `ai_usage_logs` |

Catatan integrasi:

- **Identitas**: `organization_members.firebase_uid` adalah satu-satunya kaitan
  ke Firebase. Tidak ada salinan profil/email/password di PostgreSQL.
- **Inspeksi**: hasil scan disimpan sebagai snapshot `scans` + `scan_images`
  lalu dikunci sebagai `inspections` + `inspection_items`. Scan yang dibuat di
  klien masuk sebagai `origin='LEGACY_FIRESTORE'` dengan
  `legacy_firestore_id` = id dari Flutter, sehingga idempoten dan tidak
  memotong kuota.
- **Foto**: `storage_backend='LOCAL'`, file JPEG di `backend/storage/inspections/`
  dan disajikan lewat `/media/...`. Ganti ke S3/R2/Firebase Storage saat hosting
  dengan mengisi `bucket` + `object_key`.
- **Langganan**: status pembayaran `PAID` membuat satu `subscriptions` aktif
  plus `quota_buckets` untuk organisasi tersebut.

## Endpoint data

Semua response memakai camelCase agar cocok dengan dashboard React dan Flutter.

| Method | Path | Keterangan |
| --- | --- | --- |
| GET | `/api/v1/dashboard/kpi?timeframe=` | KPI per periode |
| GET | `/api/v1/dashboard/activity?granularity=` | Grafik aktivitas |
| GET | `/api/v1/dashboard/compliance` | Donut kepatuhan gizi |
| GET | `/api/v1/dashboard/regions` | Ekosistem wilayah |
| GET | `/api/v1/users` | List pengguna (search, pagination) |
| GET/POST | `/api/v1/users`, `/api/v1/users/{uid}` | Profil & upsert |
| PATCH | `/api/v1/users/{uid}/status` | Verifikasi pengguna |
| GET | `/api/v1/inspections` | Ringkasan inspeksi |
| GET | `/api/v1/inspections/full` | Inspeksi lengkap (komponen + nutrisi) |
| GET | `/api/v1/inspections/{id}` | Detail inspeksi |
| POST | `/api/v1/inspections` | Simpan inspeksi dari Flutter (termasuk `imageBase64`) |
| GET | `/media/inspections/{file}` | File foto hasil scan |
| GET | `/api/v1/plans` | Paket langganan |
| GET/POST | `/api/v1/transactions` | Transaksi langganan |
| PATCH | `/api/v1/transactions/{orderId}/status` | Update status pembayaran |
| GET | `/health/db` | Cek koneksi PostgreSQL |

Dashboard menghitung periode kalender dalam WIB. KPI pengguna, SPPG, dan sekolah
menampilkan jumlah terdaftar hingga akhir periode. Akun premium mengikuti status
saat ini. Penilaian dihitung dari waktu scan, dan pendapatan dari harga paket
pesanan berstatus `settlement` pada tanggal pembayaran (tanggal pembuatan untuk
pesanan lama tanpa tanggal pembayaran). `timeframe=Kustom` menerima `startDate`
dan `endDate` inklusif dalam format YYYY-MM-DD. Keduanya boleh dikosongkan untuk
menggunakan 30 hari terakhir. Grafik membandingkan dua periode berurutan dan
mengisi jam atau hari tanpa inspeksi dengan nol. Kepatuhan memisahkan inspeksi
yang belum dikunci dari hasil verifikasi sesuai dan tidak sesuai. Persentase
target volume adalah jumlah pemeriksaan hari ini dibagi total kapasitas porsi
harian SPPG aktif di provinsi tersebut, dikalikan 100. API mengembalikan 0 jika
kapasitasnya 0. Pemeriksaan tanpa informasi wilayah masuk ke “Belum diketahui”.

## Foto hasil scan & bounding box

`POST /api/v1/inspections` menerima `imageBase64` (data URL atau base64 polos).
Server menormalkan gambar ke RGB, menyimpannya sebagai JPEG di
`storage/inspections/<id>.jpg`, lalu mengembalikan `imageUrl`
(`/media/inspections/<id>.jpg`) yang siap dipakai `Image.network` di Flutter.

Tiap komponen boleh membawa `bbox` dengan koordinat ternormalisasi 0..1
terhadap lebar/tinggi gambar:

```json
{
  "id": "insp-001",
  "imageBase64": "data:image/jpeg;base64,...",
  "components": [
    {
      "name": "Nasi Putih",
      "calories": 180,
      "bbox": { "x": 0.05, "y": 0.10, "width": 0.40, "height": 0.50 }
    }
  ]
}
```

Saat dibaca, `GET /api/v1/inspections` dan `/inspections/full` menyertakan
`imageUrl`; `GET /api/v1/inspections/{id}` mengembalikan `imageUrl` beserta
`bbox` per komponen. Batas ukuran gambar 12 MB, dan field `imageUrl` bernilai
`null` untuk inspeksi lama tanpa foto.

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
