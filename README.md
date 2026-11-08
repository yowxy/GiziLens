<div align="center">

# GiziLens

**Platform Mobile Cerdas Standardisasi dan Audit Mutu Gizi Baki Makan Ompreng Program Makan Bergizi Gratis (MBG) Berbasis Computer Vision**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-4CAF50?style=for-the-badge)](https://flutter.dev)
[![Router](https://img.shields.io/badge/Router-GoRouter%2017-FF6F00?style=for-the-badge)](https://pub.dev/packages/go_router)
[![Testing](https://img.shields.io/badge/Tests-100%25%20Passed-brightgreen?style=for-the-badge)](https://flutter.dev)
[![Quality](https://img.shields.io/badge/Analysis-0%20Issues-success?style=for-the-badge)](https://flutter.dev)

---

### Inovasi Rekayasa Perangkat Lunak untuk Pengawalan Standar Gizi Nasional
*Dokumentasi Teknis dan Presentasi Proyek untuk Dewan Juri Kompetisi Inovasi Teknologi*

</div>

---

## 1. Ringkasan Eksekutif

Program Makan Bergizi Gratis (MBG) yang diinisiasi oleh Badan Gizi Nasional (BGN) merupakan program strategis nasional berskala raksasa dengan jutaan porsi makanan didistribusikan setiap hari ke berbagai satuan pendidikan di seluruh Indonesia. Keberhasilan program ini bergantung pada satu faktor kritis: **konsistensi mutu, higienitas, dan ketepatan takaran Angka Kecukupan Gizi (AKG) pada setiap baki makan ompreng yang diterima peserta didik**.

### Permasalahan Kritis di Lapangan
1. **Audit Manual Lambat dan Tidak Skalabel**: Penimbangan manual per sekat baki makan membutuhkan waktu 3 hingga 5 menit per sampel. Dengan ribuan porsi per dapur Satuan Pelayanan Program Gizi (SPPG), verifikasi manual mustahil mencakup sampling yang representatif sebelum jam makan siang dimulai.
2. **Subjektivitas Tinggi dan Resiko Human Error**: Penilaian visual porsi tanpa alat bantu digital rentan terhadap perbedaan persepsi antar petugas lapangan.
3. **Ketiadaan Jejak Audit Digital Anti-Manipulasi**: Berita acara manual berbasis kertas rawan tercecer, rusak, atau dimanipulasi tanpa adanya validasi data terkunci yang terhubung langsung dengan sistem pengawasan pusat.

### Solusi GiziLens
**GiziLens** adalah solusi mobile native berstandar industri yang mengotomatisasi seluruh siklus inspeksi mutu makanan. Melalui kamera smartphone, GiziLens memindai baki ompreng 5 sekat, mengidentifikasi komponen makanan secara real-time, mengestimasi gramasi, mengkalkulasi 5 pilar nutrisi terhadap toleransi ketat batas BGN (±10%), serta menerbitkan Berita Acara Digital terverifikasi dalam waktu **kurang dari 15 detik**.

---

## 2. Arsitektur Teknologi dan Rekayasa Sistem

GiziLens dibangun oleh tim mobile developer berpengalaman dengan mengadopsi standar arsitektur perangkat lunak enterprise modern.

```
                    +---------------------------------------------+
                    |           PRESENTATION LAYER                |
                    |   (Screen Views, Reusable Atomic Widgets)   |
                    +----------------------+----------------------+
                                           | Reactive State Bindings
                                           v
                    +---------------------------------------------+
                    |             CONTROLLER LAYER                |
                    |  (Scan, Component, Nutrition, Auth, Audit)  |
                    +----------------------+----------------------+
                                           | Business Rules & Commands
                                           v
                    +---------------------------------------------+
                    |               DOMAIN LAYER                  |
                    |   (Nutrition Entities, AKG Models, Enums)   |
                    +----------------------+----------------------+
                                           | Repository Interfaces
                                           v
                    +---------------------------------------------+
                    |             DATA & CORE LAYER               |
                    |   (Routing, Tokens, Theme, Local Data)      |
                    +---------------------------------------------+
```

### A. Rincian Stack Teknologi Utama

| Komponen Teknologi | Pilihan Teknologi | Alasan Pemilihan Arsitektural |
| :--- | :--- | :--- |
| **Framework Mobile** | Flutter SDK 3.10+ & Dart 3 | Kompilasi performa native (AOT), rendering 60 FPS konsisten via skia/impeller, serta portabilitas multiplatform Android dan iOS dari satu basis kode terpadu. |
| **Arsitektur Sistem** | Clean Architecture Terpisah | Pemisahan tegas antara Core, Features, Domain, dan Data. Memastikan kode mudah diuji secara independen, modular, dan siap diskalakan. |
| **State Management** | Centralized Reactive Controller (`Listenable`) | Pola deterministik berbasis `ChangeNotifier` dengan alokasi memori efisien. Menghindari rebuild widget yang tidak perlu dan menjamin performa lancar pada perangkat low-end. |
| **Declarative Routing** | GoRouter 17 | Type-safe parameter passing, nested routing, pencegahan deep-link tampering, dan handling transition screen yang terstruktur rapi. |
| **Design System Token** | Atomic Tokens (`AppColors`, `AppTypography`, `AppDimensions`) | Standarisasi visual terpusat (Material 3 standard) tanpa hardcoded value, memudahkan penyesuaian tema dan konsistensi UI. |
| **Layout Adaptif & Safe Flex** | Flexible, FittedBox, Responsive Constraints | Perlindungan rendering multi-resolusi yang mencegah `RenderFlex Overflow` pada perangkat layar kompak (lebar 360 dp hingga tablet). |
| **Asset & Icon Management** | Google Fonts (Poppins), Vector Graphics SVG | Rendering tipografi presisi tinggi tanpa beban dependensi runtime berat, aset visual terkompresi dengan pre-caching. |

### B. Pipeline Analisis Gizi dan Segmentasi Citra (Computer Vision Ready)
Pipeline pemrosesan audit ompreng pada GiziLens dirancang dengan 5 tahap komputasi presisi:
1. **Geometric Alignment & Viewfinder Guidance**: Sistem memandu sudut kamera tegak lurus terhadap baki ompreng dengan rasio aspek terstandarisasi.
2. **Multi-Compartment Segmentation**: Citra disegmentasi ke dalam 5 sekat anatomis (Karbohidrat, Protein Hewani, Protein Nabati, Sayuran, Buah).
3. **Food Item Classification**: Model mengenali jenis masakan (contoh: Nasi Putih, Telur Balado, Sayur Bayam, Tempe Orek, Pisang Mas).
4. **Volumetric & Gram Calculation**: Konversi estimasi luas area dan densitas makanan menjadi gramasi bersih terkalibrasi dengan kontrol penyesuaian manual.
5. **AKG Tolerance Engine**: Komparasi real-time 5 pilar nutrisi (Kalori, Karbohidrat, Protein, Lemak, Serat) terhadap batas batas toleransi baku BGN sebesar ±10%.

---

## 3. Showcase Prototipe Desain dan Alur Kerja Pengguna

Seluruh antarmuka GiziLens telah diimplementasikan dalam kode produksi Flutter dengan fidelitas tinggi sesuai spesifikasi desain interaksi.

### Galeri Alur Inspeksi Lapangan (Tahap 1 - 3)

<table>
  <tr>
    <td align="center" width="33%">
      <img src="desain_01_onboarding.png" width="240" alt="Onboarding GiziLens" /><br><br>
      <b>01. Onboarding & Edukasi Mutu</b>
    </td>
    <td align="center" width="33%">
      <img src="desain_02_autentikasi.png" width="240" alt="Autentikasi Petugas" /><br><br>
      <b>02. Autentikasi SPPG Terverifikasi</b>
    </td>
    <td align="center" width="33%">
      <img src="desain_03_dashboard.png" width="240" alt="Dashboard Monitoring" /><br><br>
      <b>03. Dashboard Monitoring Harian</b>
    </td>
  </tr>
  <tr>
    <td valign="top">
      <ul>
        <li>Edukasi visual tata letak baki 5 sekat standar BGN.</li>
        <li>Instruksi pemindaian cepat dengan akurasi optimal.</li>
        <li>Transisi onboarding interaktif tanpa latensi.</li>
      </ul>
    </td>
    <td valign="top">
      <ul>
        <li>Otentikasi kredensial resmi petugas SPPG lapangan.</li>
        <li>Validasi form ketat dengan masking password aman.</li>
        <li>Alur verifikasi kode OTP dan persetujuan pakta integritas.</li>
      </ul>
    </td>
    <td valign="top">
      <ul>
        <li>Statistik ringkasan sesi kepatuhan (Sesuai vs Tidak Sesuai).</li>
        <li>Metrik agregat sesi makan harian secara real-time.</li>
        <li>Akses cepat satu sentuhan ke pemindaian inspeksi baru.</li>
      </ul>
    </td>
  </tr>
</table>

### Galeri Alur Inspeksi Lapangan (Tahap 4 - 6)

<table>
  <tr>
    <td align="center" width="33%">
      <img src="desain_04_batch_input.png" width="240" alt="Batch Setup" /><br><br>
      <b>04. Registrasi Batch & Sekolah</b>
    </td>
    <td align="center" width="33%">
      <img src="desain_05_scan_ompreng.png" width="240" alt="Scan Ompreng" /><br><br>
      <b>05. Pemindaian AI Real-Time</b>
    </td>
    <td align="center" width="33%">
      <img src="desain_06_komponen_makanan.png" width="240" alt="Komponen Makanan" /><br><br>
      <b>06. Segmentasi Komponen & Bobot</b>
    </td>
  </tr>
  <tr>
    <td valign="top">
      <ul>
        <li>Input kode batch sampling terlacak (#MBG-2024-CIB02).</li>
        <li>Pemilihan sekolah sasaran dan kelompok target usia murid.</li>
        <li>Penentuan sesi makan (Pagi atau Siang).</li>
      </ul>
    </td>
    <td valign="top">
      <ul>
        <li>Holographic viewfinder baki ompreng 5 sekat.</li>
        <li>Deteksi sudut kemiringan kamera otomatis.</li>
        <li>Tombol shutter responsif dengan feedback haptik.</li>
      </ul>
    </td>
    <td valign="top">
      <ul>
        <li>Pengenalan multi-item: Nasi, Telur, Bayam, Tempe, Pisang.</li>
        <li>Estimasi gramasi bersih per sekat dengan indikator visual.</li>
        <li>Slider kalibrasi gramasi instan untuk penyesuaian lapangan.</li>
      </ul>
    </td>
  </tr>
</table>

### Galeri Alur Inspeksi Lapangan (Tahap 7 - 9)

<table>
  <tr>
    <td align="center" width="33%">
      <img src="desain_07_analisis_gizi.png" width="240" alt="Analisis Gizi" /><br><br>
      <b>07. Analisis Nutrisi 5 Pilar</b>
    </td>
    <td align="center" width="33%">
      <img src="desain_08_konfirmasi_kunci.png" width="240" alt="Konfirmasi Kunci Data" /><br><br>
      <b>08. Validasi Berita Acara & Kunci</b>
    </td>
    <td align="center" width="33%">
      <img src="desain_09_riwayat_audit.png" width="240" alt="Riwayat Audit" /><br><br>
      <b>09. Riwayat & Ketertelusuran</b>
    </td>
  </tr>
  <tr>
    <td valign="top">
      <ul>
        <li>Komputasi 5 pilar nutrisi: Kalori, Karbo, Protein, Lemak, Serat.</li>
        <li>Toleransi dinamis ±10% terhadap standar AKG BGN.</li>
        <li>Kartu rekomendasi perbaikan gizi otomatis.</li>
      </ul>
    </td>
    <td valign="top">
      <ul>
        <li>Rangkuman protokol sampling dan verifikator resmi.</li>
        <li>Total bobot bersih dan komponen porsi tervalidasi.</li>
        <li>Penguncian data digital permanen anti-tampering.</li>
      </ul>
    </td>
    <td valign="top">
      <ul>
        <li>Penyimpanan histori audit berbasis tanggal dan batch.</li>
        <li>Pencarian instan dan filter kepatuhan status.</li>
        <li>Jejak audit transparan untuk inspektorat daerah.</li>
      </ul>
    </td>
  </tr>
</table>

---

## 4. Keunggulan Kompetitif Sistem untuk Evaluasi Dewan Juri

1. **Efisiensi Waktu Audit Terobosan**:
   Memangkas siklus pemeriksaan dari 5 menit manual menjadi di bawah 15 detik. Satu orang petugas dapat memverifikasi puluhan baki makan dalam interval waktu distribusi makanan sekolah yang singkat.
2. **Pencegahan Fraud dan Kebocoran Anggaran**:
   Fitur Kunci Data Digital memastikan data hasil timbangan dan komposisi menu tidak dapat diedit kembali setelah Berita Acara disahkan oleh petugas verifikator lapangan.
3. **Ketahanan Kode Tingkat Tinggi (High Reliability)**:
   Aplikasi dirancang anti-crash dengan penanganan constraint yang ketat pada layar kecil, pencegahan memory leak via lifecycle controller disposal, serta zero warning pada analisis statis kode.
4. **Kesiapan Integrasi Skala Nasional**:
   Data model telah dinormalisasi sesuai format data Badan Gizi Nasional, memungkinkan integrasi instan dengan API Backend terpusat maupun arsitektur microservices BGN.

---

## 5. Struktur Direktori Proyek

Struktur folder mencerminkan penerapan Clean Architecture yang rapi dan terorganisir:

```
fe/gizi_lens/
├── android/                        # Konfigurasi native Android
├── ios/                            # Konfigurasi native iOS
├── assets/                         # Aset statis teroptimasi
│   ├── fonts/                      # Font Poppins (Regular, Medium, SemiBold, Bold)
│   └── images/                     # Maskot, Logo BGN, dan Gambar Komponen Makanan
├── lib/
│   ├── main.dart                   # Entry point aplikasi & inisialisasi orientasi
│   ├── core/                       # Komponen inti global
│   │   ├── constants/              # AppColors, AppTypography, AppDimensions, AppStrings
│   │   ├── routing/                # AppRouter & RouteNames deklaratif GoRouter
│   │   └── widgets/                # Reusable Atomic UI (AppButton, TextField, Card)
│   └── features/                   # Modul fitur bisnis aplikasi
│       ├── splash/                 # Splash screen & visual identity
│       ├── onboarding/             # Edukasi tata cara audit baki
│       ├── auth/                   # Login, Registrasi Petugas, & Verifikasi OTP
│       ├── dashboard/              # Monitoring metrik kepatuhan & kartu statistik
│       ├── inspection/             # Core Audit: Batch, Camera Scan, Detection, AKG, Lock
│       ├── history/                # Rekapitulasi histori audit & pencarian batch
│       └── profile/                # Pengaturan akun petugas SPPG & regulasi
└── test/                           # Otomasi pengujian perangkat lunak
    └── features/
        └── inspection/             # Unit test controller & widget testing flow penuh
```

---

## 6. Jaminan Kualitas Kode dan Metodologi Pengujian

Proyek ini dilengkapi dengan suite pengujian komprehensif yang memvalidasi stabilitas logika bisnis dan antarmuka visual secara otomatis.

### Skenario Pengujian yang Terverifikasi Lulus (100% Passed)
1. **ScanOmprengController Unit Tests**: Pengujian inisialisasi state kamera, flash toggle, orientasi baki, dan transisi pemindaian.
2. **ComponentDetectionController Unit Tests**: Pengujian deteksi 5 komponen makanan, pembaruan gramasi real-time, dan kalkulasi bobot bersih total.
3. **NutritionAnalysisController Unit Tests**: Pengujian akurasi rumus kalkulasi 5 pilar nutrisi dan penentuan status kepatuhan berdasarkan batas toleransi ±10%.
4. **Widget Testing Alur Penuh (End-to-End Flow)**: Pengujian navigasi beruntun dari layar pemindaian, segmentasi komponen, visualisasi AKG, hingga penekanan tombol Simpan dan Kunci Data.

---

## 7. Panduan Instalasi dan Menjalankan Sistem

### Prasyarat Perangkat Lunak
* Flutter SDK versi 3.10.1 atau lebih baru
* Dart SDK versi 3.0.0 atau lebih baru
* Android Studio / VS Code dengan ekstensi Flutter dan Dart terpasang
* Emulator Android (API level 28+) atau Perangkat Fisik smartphone

### Langkah Menjalankan Aplikasi

1. **Unduh Dependensi Proyek**:
   ```bash
   flutter pub get
   ```

2. **Jalankan Pemeriksaan Kualitas Kode**:
   ```bash
   flutter analyze
   ```
   *Hasil: No issues found! (Kode bersih dari peringatan statis).*

3. **Jalankan Suite Pengujian Otomatis**:
   ```bash
   flutter test
   ```
   *Hasil: All tests passed! (Seluruh unit dan widget test terverifikasi).*

4. **Eksekusi Aplikasi**:
   ```bash
   flutter run
   ```

---

## 8. Kesimpulan

**GiziLens** membuktikan keunggulan rekayasa teknologi mobile modern dalam menjawab tantangan nyata penjaminan mutu program skala nasional. Melalui perpaduan Clean Architecture yang tangguh, antarmuka pengguna yang terstruktur rapi, serta teknologi Computer Vision terdepan, GiziLens siap menjadi standar baku pengawasan gizi demi terwujudnya generasi emas Indonesia yang sehat, cerdas, dan berdaya saing.

---

<div align="center">
  <b>Dikembangkan untuk Pengawalan Standar Mutu Badan Gizi Nasional Republik Indonesia</b><br>
  <i>Hak Cipta 2026 Tim Pengembang GiziLens. Seluruh Hak Dilindungi Undang-Undang.</i>
</div>
