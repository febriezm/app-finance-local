# MyFinance — iOS Personal Local-First Finance App

**MyFinance** adalah aplikasi manajemen keuangan pribadi *local-first*, 100% *offline-only* untuk platform iOS (dan Flutter cross-platform), dirancang dengan standar **Apple Human Interface Guidelines (HIG)** dan Clean Architecture.

Seluruh data finansial tersimpan aman di sandbox lokal perangkat pengguna tanpa server backend, tanpa akun/login cloud, tanpa unggah jaringan, dan tanpa analitik pihak ketiga.

---

## 🏛️ Arsitektur & Prinsip Desain

1. **Local-First & Offline-Only (Zero Cloud)**
   - Menggunakan mesin basis data **SQLite** lokal via **Drift ORM**.
   - Tidak ada transmisi data finansial atau foto struk keluar dari perangkat.
2. **Akuntansi Berbasis Buku Besar (Double-Entry Ledger Principle)**
   - Saldo dompet dihitung secara deterministik dari riwayat mutasi transaksi:
     $$\text{Saldo} = \text{Saldo Awal} + \text{Pemasukan} + \text{Transfer Masuk} - \text{Pengeluaran} - \text{Transfer Keluar}$$
   - Transaksi internal transfer tidak mengubah total kekayaan/aset bersih maupun total income/expense.
   - Semua nominal disimpan dalam satuan integer Rupiah (`int`), menghilangkan potensi *floating-point rounding error*.
3. **Pemindai Struk On-Device (OCR + Parser)**
   - Ekstraksi teks struk belanja diproses 100% di perangkat.
   - Hasil OCR selalu masuk sebagai draft dan wajib ditinjau serta dikonfirmasi pengguna sebelum masuk ke buku besar.
4. **Pencadangan & Pemulihan Tervalidasi (Schema v1)**
   - Berkas cadangan berupa arsip JSON terstruktur dengan validasi integritas skema dan relasi Foreign Key SQLite.
   - Pemulihan berjalan secara atomik menggunakan transaksi SQLite (`db.transaction`).
5. **Keamanan Biometrik (Face ID / Touch ID / Passcode)**
   - Dilindungi menggunakan `local_auth` yang terintegrasi dengan Apple Secure Enclave.
   - Penguncian otomatis saat aplikasi masuk ke latar belakang (*background*).

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── app/                        # Bootstrapping aplikasi, Router (GoRouter), ProviderScope
├── core/
│   ├── constants/              # Konfigurasi konstanta global & nama aplikasi
│   ├── database/               # Mesin Drift SQLite (AppDatabase, DAOs, Migrasi)
│   ├── errors/                 # Domain Failures & Exceptions
│   ├── formatting/             # Formatter Tanggal & Mata Uang Rupiah (CurrencyFormatter)
│   ├── services/               # AppLockService (Biometrik lokal)
│   ├── theme/                  # Desain Token Apple HIG (Warna, Tipografi, Spacing, Tema)
│   └── utils/                  # AppHaptics, FileExportHelper, FilePickerHelper
├── features/
│   ├── wallets/                # Engine Saldo, CRUD Dompet, Status Arsip
│   ├── categories/             # Manajemen Kategori Pemasukan & Pengeluaran
│   ├── transactions/           # Pencatatan Transaksi (Income, Expense, Transfer) & Ledger
│   ├── budgets/                # Anggaran Bulanan, Limit Kategori, Indikator Real-time
│   ├── receipt_scanner/        # Pemindai Struk Belanja, On-Device OCR, Parser, Review
│   ├── reports/                # Laporan Finansial, Perbandingan Bulan, Ekspor PDF & CSV
│   ├── backup_restore/         # Ekspor & Impor Cadangan JSON, Validasi Atomik, Reset Data
│   ├── security/               # Layar Kunci Biometrik (AppLockScreen, AppLockListener)
│   └── settings/               # Pengaturan Tema (Sistem/Terang/Gelap), Kunci Biometrik
└── shared/                     # Komponen UI Reusable (AppCard, LoadingIndicator, dsb.)
```

---

## 🚀 Cara Menjalankan Proyek

### Prasyarat
- **Flutter SDK**: `>= 3.19.0` (Dart `>= 3.3.0`)
- **Xcode** (untuk build iOS / Simulator)

### Menjalankan di Simulator iOS
```bash
# Ambil dependencies
flutter pub get

# Jalankan kode generator Drift & Freezed jika diperlukan
dart run build_runner build --delete-conflicting-outputs

# Jalankan aplikasi di iOS Simulator
flutter run -d iPhone
```

### Menjalankan Pengujian Kualitas (Testing & Analysis)
```bash
# Analisis kode statis (Harus 0 issues)
flutter analyze

# Menjalankan seluruh test suite (63 pengujian lulus)
flutter test
```

### Pratinjau Web Lokal (Development Preview)
```bash
# Build paket web release
flutter build web --release

# Jalankan server lokal
python -m http.server 8085 --directory build/web
# Akses di browser: http://localhost:8085
```

---

## 🛡️ Hak Akses iOS (`Info.plist`)
Aplikasi telah dikonfigurasi dengan deskripsi izin transparan berorientasi privasi:
- `NSCameraUsageDescription`: *"MyFinance memerlukan akses kamera untuk memindai struk belanja secara offline."*
- `NSPhotoLibraryUsageDescription`: *"MyFinance memerlukan akses galeri foto untuk memilih gambar struk belanja secara offline."*
- `NSFaceIDUsageDescription`: *"MyFinance menggunakan Face ID untuk mengamankan data keuangan pribadi Anda."*

---

## 📋 Hasil Pengujian & Verifikasi Phase 5 (100% Lulus)
- **Unit & Integration Tests**: 63 dari 63 tests passed (100%).
- **Acceptance Criteria Section 12**: Seluruh 10 kriteria lulus pengujian end-to-end (`test/integration/acceptance_criteria_mvp_test.dart`).
- **Static Analysis**: `flutter analyze` $\rightarrow$ **0 issues**.
