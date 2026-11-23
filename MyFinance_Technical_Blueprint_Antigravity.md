# MyFinance — Technical Blueprint & Build Specification
**Dokumen instruksi untuk Antigravity**  
**Platform:** iOS (iPhone) · **Framework:** Flutter/Dart · **Mode:** Personal, local-only  
**Versi dokumen:** 1.0

---

## 1. Tujuan Produk

Bangun aplikasi iOS bernama **MyFinance** untuk pencatatan dan pengendalian keuangan pribadi. Aplikasi harus memungkinkan satu pengguna mengelola beberapa sumber dana, mencatat pemasukan/pengeluaran/transfer, memantau saldo, mengatur batas pengeluaran bulanan, membaca struk melalui kamera, serta melihat laporan bulanan.

Aplikasi harus **local-first dan local-only** pada versi ini:
- Seluruh data transaksi dan konfigurasi disimpan di perangkat.
- Aplikasi tetap berfungsi tanpa koneksi internet.
- Tidak ada akun, login, backend, cloud sync, atau pengiriman data otomatis.
- Foto struk dan hasil OCR disimpan secara lokal.
- Fitur AI eksternal tidak boleh diam-diam mengirim foto atau data ke layanan pihak ketiga.

## 2. Keputusan Teknis yang Wajib Diikuti

| Area | Keputusan |
|---|---|
| Target | iOS, desain responsif untuk iPhone |
| Framework | Flutter stable + Dart |
| Arsitektur | Feature-first, layered architecture, repository pattern |
| State management | Riverpod |
| Routing | GoRouter |
| Database | SQLite melalui Drift |
| Penyimpanan aman | `flutter_secure_storage` hanya untuk secret lokal bila benar-benar diperlukan |
| Kamera | `camera` atau `image_picker` |
| OCR | On-device OCR; utamakan Apple Vision melalui platform channel/plugin yang terpelihara, alternatif ML Kit on-device |
| Grafik | `fl_chart` |
| Format uang | IDR, integer Rupiah; jangan gunakan floating point |
| Export | PDF dan CSV lokal |
| Sinkronisasi | Tidak ada pada MVP |
| Autentikasi | Tidak diperlukan untuk single-user lokal |
| Bahasa UI | Bahasa Indonesia, dengan struktur siap dilokalkan |
| Zona waktu | Simpan waktu transaksi secara konsisten; tampilkan dalam zona waktu perangkat |

### Catatan penting tentang “OCR + AI hybrid”
Pilihan hybrid harus diterapkan dengan aman dalam konteks local-only:
1. OCR dijalankan di perangkat.
2. Ekstraksi awal dilakukan dengan parser lokal berbasis pola/heuristik.
3. Pengguna mengoreksi hasil sebelum transaksi disimpan.
4. Jangan mengaktifkan AI cloud pada MVP karena bertentangan dengan keputusan local-only.
5. Buat interface `ReceiptUnderstandingService` agar AI lokal atau AI cloud yang memerlukan persetujuan eksplisit dapat ditambahkan di masa depan. Implementasi awal harus tetap bekerja tanpa jaringan.

## 3. Ruang Lingkup MVP

### Wajib ada
1. Dashboard ringkasan saldo dan aktivitas bulan berjalan.
2. Pengelolaan wallet/sumber dana.
3. Pencatatan income, expense, dan transfer.
4. Kategori transaksi bawaan dan kategori kustom.
5. Anggaran bulanan total dan per kategori.
6. Riwayat transaksi dengan filter bulan, jenis, wallet, dan kategori.
7. Receipt scanner: ambil/pilih foto, crop/rotate bila perlu, OCR, ekstraksi awal, review, simpan.
8. Laporan bulanan dan perbandingan periode sederhana.
9. Pengaturan mata uang IDR, tema, backup/restore lokal.
10. Penguncian aplikasi dengan Face ID/Touch ID atau passcode opsional.

### Di luar MVP
- Multi-user/family finance.
- Login dan cloud backend.
- Sinkronisasi lintas perangkat.
- Open banking atau impor mutasi otomatis.
- AI cloud tanpa persetujuan.
- Manajemen investasi, utang kompleks, dan pajak.
- Widget iOS dan Apple Watch (dapat menjadi fase lanjutan).

## 4. Modul dan User Flow

### 4.1 Dashboard
Tampilkan:
- Total saldo seluruh wallet aktif.
- Total pemasukan bulan berjalan.
- Total pengeluaran bulan berjalan.
- Sisa budget bulan berjalan.
- Grafik income vs expense.
- Progress budget per kategori.
- Transaksi terbaru.
- Tombol cepat: Tambah Pengeluaran, Tambah Pemasukan, Transfer, Scan Struk.

Definisi saldo total: jumlah saldo seluruh wallet yang termasuk aset kas. Kartu kredit/liabilitas tidak boleh dijumlahkan sebagai saldo aset; bila didukung, tampilkan sebagai kewajiban terpisah.

### 4.2 Wallet
Pengguna dapat membuat, mengubah, mengarsipkan wallet:
- Nama wallet, tipe (cash/bank/e-wallet/other), saldo awal, tanggal saldo awal, warna/icon, status aktif.
- Saldo berjalan dihitung dari saldo awal ditambah mutasi transaksi.
- Wallet tidak dihapus permanen jika sudah memiliki transaksi; gunakan arsip.
- Transfer harus memilih wallet asal dan tujuan yang berbeda.

### 4.3 Transaksi
Jenis:
- `income`: menambah saldo wallet.
- `expense`: mengurangi saldo wallet.
- `transfer`: mengurangi wallet asal dan menambah wallet tujuan, tidak masuk total income/expense.

Data transaksi:
- ID UUID.
- Jenis.
- Nominal dalam integer Rupiah.
- Tanggal dan waktu.
- Wallet sumber.
- Wallet tujuan untuk transfer.
- Kategori.
- Merchant/payee opsional.
- Deskripsi/catatan.
- Attachment struk opsional.
- Sumber input (`manual`, `receipt_scan`, `recurring`).
- Status (`confirmed`, `voided`).
- Timestamp pembuatan/perubahan.

Validasi:
- Nominal harus lebih besar dari nol.
- Expense/income wajib memiliki satu wallet.
- Transfer wajib memiliki wallet asal dan tujuan yang berbeda.
- Kategori harus sesuai jenis transaksi.
- Transaksi voided tidak memengaruhi saldo maupun laporan.
- Edit/hapus transaksi harus memperbarui semua ringkasan turunan.

### 4.4 Budget
- Budget ditentukan per bulan kalender (`YYYY-MM`).
- Mendukung satu total budget dan limit per kategori.
- Pengeluaran dihitung berdasarkan transaksi expense berstatus confirmed pada periode dan kategori terkait.
- Transfer dan income tidak mengurangi budget.
- Tampilkan status normal, mendekati batas, dan terlampaui.
- Ambang notifikasi default 75%, 90%, 100%; dapat diubah pengguna.
- Hindari menghitung satu expense dua kali pada total budget dan kategori.

### 4.5 Receipt Scanner
Flow:
1. Pengguna membuka Scan Receipt.
2. Ambil foto dari kamera atau pilih dari Photos.
3. Tampilkan preview dan opsi crop/rotate.
4. Jalankan OCR on-device.
5. Parser lokal mencoba mengenali merchant, tanggal, subtotal, pajak, total, dan item.
6. Tampilkan hasil beserta confidence/indikasi field yang belum pasti.
7. Pengguna memilih wallet dan kategori, mengoreksi nilai.
8. Simpan sebagai expense setelah pengguna menekan konfirmasi.
9. Simpan gambar asli/hasil crop sebagai attachment lokal sesuai preferensi.

Aturan:
- Jangan pernah auto-save transaksi dari hasil OCR tanpa review.
- Jika total tidak ditemukan atau ambigu, wajib minta input manual.
- Simpan teks OCR mentah secara lokal hanya jika dibutuhkan untuk audit/debug; sediakan opsi menghapus.
- Jelaskan izin kamera dan foto sebelum meminta permission.
- Jangan mengunggah gambar atau teks OCR ke server.

Interface yang disiapkan:
```dart
abstract interface class ReceiptOcrService {
  Future<OcrResult> recognize(File image);
}

abstract interface class ReceiptUnderstandingService {
  Future<ReceiptDraft> parse(OcrResult result);
}
```
Implementasi MVP `ReceiptUnderstandingService` menggunakan parser lokal. Implementasi AI dapat ditambahkan kelak sebagai adapter terpisah dengan consent eksplisit.

### 4.6 Laporan
- Ringkasan income, expense, net cashflow, saldo akhir.
- Breakdown expense per kategori dan wallet.
- Tren harian/mingguan dalam bulan.
- Perbandingan dengan bulan sebelumnya.
- Daftar transaksi yang membentuk angka laporan.
- Export PDF/CSV melalui share sheet iOS.

Rumus:
- `Saldo wallet akhir = saldo awal + income + transfer masuk - expense - transfer keluar`
- `Net cashflow = total income - total expense`
- `Saldo total aset = jumlah saldo wallet aset aktif`
- `Sisa budget = budget - expense terhitung`
- Transfer tidak termasuk income, expense, atau net cashflow.

## 5. Arsitektur Aplikasi

Gunakan **feature-first layered architecture**. UI tidak boleh mengakses database secara langsung.

Lapisan:
1. **Presentation** — screen, widget, controller/notifier, state.
2. **Domain** — entity, value object, repository contract, use case, business rules.
3. **Data** — Drift table/DAO, DTO/mapper, repository implementation, local services.
4. **Core** — routing, theme, formatting, error handling, shared utilities.

Alur data:
`Screen → Riverpod Notifier → Use Case → Repository Contract → Drift Repository → SQLite`

Ketentuan:
- Semua operasi tulis transaksi menggunakan database transaction/SQL transaction.
- Jangan menyimpan saldo berjalan sebagai satu-satunya sumber kebenaran. Saldo harus dapat direkonstruksi dari opening balance + ledger.
- Jika cache saldo disimpan untuk performa, cache harus dapat dibangun ulang dan divalidasi.
- Gunakan UUID untuk primary key.
- Gunakan foreign key dan aktifkan foreign key enforcement SQLite.
- Gunakan migration Drift untuk perubahan skema.
- Gunakan decimal-free integer Rupiah (`INTEGER`).
- Semua query laporan harus mengecualikan transaksi voided.

## 6. Struktur Folder Flutter

```text
myfinance/
├── android/
├── ios/
│   ├── Runner/
│   └── Podfile
├── assets/
│   ├── icons/
│   ├── images/
│   └── fonts/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   ├── app_providers.dart
│   │   └── lifecycle_observer.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   ├── tables/
│   │   │   ├── daos/
│   │   │   └── migrations/
│   │   ├── errors/
│   │   ├── extensions/
│   │   ├── formatting/
│   │   ├── permissions/
│   │   ├── services/
│   │   ├── theme/
│   │   └── utils/
│   ├── shared/
│   │   ├── widgets/
│   │   ├── models/
│   │   └── providers/
│   └── features/
│       ├── onboarding/
│       ├── dashboard/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── wallets/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── transactions/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── categories/
│       ├── budgets/
│       ├── receipt_scanner/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── reports/
│       ├── settings/
│       └── backup_restore/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── integration_test/
├── analysis_options.yaml
└── pubspec.yaml
```

Setiap feature yang kompleks mengikuti struktur:
```text
feature_name/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/
    ├── screens/
    └── widgets/
```

Feature sederhana boleh lebih ringkas, tetapi business logic tetap dipisahkan dari widget.

## 7. Database Schema (SQLite / Drift)

Gunakan UUID TEXT sebagai primary key dan timestamp ISO-8601 UTC sebagai penyimpanan waktu. Nominal Rupiah disimpan sebagai INTEGER.

### 7.1 `wallets`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| name | TEXT | Nama wallet |
| type | TEXT | cash/bank/e_wallet/other |
| opening_balance | INTEGER | Saldo awal |
| opening_date | TEXT | Tanggal saldo awal |
| currency_code | TEXT | Default IDR |
| icon_key | TEXT nullable | Identifier icon |
| color_hex | TEXT nullable | Warna |
| is_archived | INTEGER | 0/1 |
| created_at | TEXT | Timestamp |
| updated_at | TEXT | Timestamp |

### 7.2 `categories`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| name | TEXT | Nama kategori |
| type | TEXT | income/expense |
| icon_key | TEXT nullable | Icon |
| color_hex | TEXT nullable | Warna |
| is_system | INTEGER | Kategori bawaan |
| is_archived | INTEGER | 0/1 |
| sort_order | INTEGER | Urutan |

### 7.3 `transactions`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| type | TEXT | income/expense/transfer |
| amount | INTEGER | Nominal positif |
| occurred_at | TEXT | Waktu transaksi |
| wallet_id | TEXT FK nullable | Wallet untuk income/expense; wallet asal untuk transfer |
| destination_wallet_id | TEXT FK nullable | Wallet tujuan transfer |
| category_id | TEXT FK nullable | Wajib untuk income/expense sesuai aturan kategori |
| merchant | TEXT nullable | Toko/penerima |
| description | TEXT nullable | Keterangan |
| notes | TEXT nullable | Catatan |
| source | TEXT | manual/receipt_scan/recurring |
| status | TEXT | confirmed/voided |
| created_at | TEXT | Timestamp |
| updated_at | TEXT | Timestamp |

Untuk transfer, `wallet_id` berarti wallet asal dan `destination_wallet_id` berarti wallet tujuan. Pastikan kedua wallet berbeda. Transfer dicatat satu kali sebagai satu transaksi dan menghasilkan dua sisi mutasi saat menghitung saldo.

### 7.4 `transaction_attachments`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| transaction_id | TEXT FK | Transaksi |
| local_path | TEXT | Path file lokal relatif |
| mime_type | TEXT | image/jpeg, dll |
| file_size | INTEGER | Byte |
| created_at | TEXT | Timestamp |

Simpan file di Application Support/Documents app sandbox, bukan path sementara dari cache kamera. Tangani backup sesuai pilihan pengguna.

### 7.5 `budgets`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| month_key | TEXT | YYYY-MM |
| total_limit | INTEGER | Limit total |
| alert_thresholds | TEXT | JSON, contoh [75,90,100] |
| carry_over_enabled | INTEGER | 0/1 |
| notes | TEXT nullable | Catatan |
| created_at | TEXT | Timestamp |
| updated_at | TEXT | Timestamp |

Tambahkan unique constraint pada `month_key` jika hanya ada satu budget bulanan.

### 7.6 `budget_category_limits`
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT PK | UUID |
| budget_id | TEXT FK | Budget |
| category_id | TEXT FK | Kategori expense |
| limit_amount | INTEGER | Batas kategori |

Tambahkan unique constraint `(budget_id, category_id)`.

### 7.7 `app_settings`
| Kolom | Tipe | Keterangan |
|---|---|---|
| key | TEXT PK | Kunci setting |
| value | TEXT | Nilai |
| updated_at | TEXT | Timestamp |

### 7.8 Index dan Constraint
Buat index minimal:
- `transactions(occurred_at)`
- `transactions(type, status, occurred_at)`
- `transactions(wallet_id, occurred_at)`
- `transactions(category_id, occurred_at)`
- `transaction_attachments(transaction_id)`
- `budgets(month_key)`

Aktifkan foreign keys. Untuk transaksi, validasi konsistensi tipe, wallet, kategori, dan nominal di domain layer serta bila memungkinkan dengan CHECK constraints di SQLite.

## 8. Perhitungan Saldo dan Budget

Gunakan ledger sebagai sumber kebenaran.

Untuk setiap wallet:
- Opening balance.
- Tambahkan income pada wallet tersebut.
- Kurangi expense pada wallet tersebut.
- Tambahkan transfer jika wallet adalah tujuan.
- Kurangi transfer jika wallet adalah asal.
- Abaikan transaksi voided.

Pseudocode:
```text
balance(wallet) =
  opening_balance
  + confirmed income on wallet
  - confirmed expense on wallet
  + confirmed transfers into wallet
  - confirmed transfers out of wallet
```

Laporan:
```text
total_income = SUM(confirmed income)
total_expense = SUM(confirmed expense)
net_cashflow = total_income - total_expense
ending_balance = opening_total + net_cashflow
                // transfer internal tidak mengubah total aset
```

Budget:
```text
spent_in_month = SUM(confirmed expense in selected month)
remaining_budget = total_limit - spent_in_month
category_spent = SUM(confirmed expense grouped by category)
```

Perhatian:
- Definisikan periode berdasarkan tanggal lokal pengguna, bukan UTC date string secara mentah.
- Hindari double count ketika menampilkan total budget dan limit kategori.
- Untuk kategori tanpa limit kategori, pengeluaran tetap masuk total budget.
- Jika total limit kategori melebihi total budget, tampilkan peringatan konfigurasi, bukan mengubah nominal diam-diam.

## 9. Paket Flutter yang Direkomendasikan

Pilih versi stabil terbaru yang saling kompatibel saat implementasi; commit `pubspec.lock`.

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: any
  go_router: any
  drift: any
  sqlite3_flutter_libs: any
  path_provider: any
  path: any
  uuid: any
  intl: any
  fl_chart: any
  camera: any
  image_picker: any
  permission_handler: any
  local_auth: any
  flutter_local_notifications: any
  pdf: any
  printing: any
  share_plus: any
  csv: any
  freezed_annotation: any
  json_annotation: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  drift_dev: any
  build_runner: any
  freezed: any
  json_serializable: any
  flutter_lints: any
```

OCR:
- Evaluasi plugin Flutter OCR yang benar-benar menjalankan recognition on-device dan mendukung iOS.
- Jika kualitas/dukungan plugin tidak memadai, buat platform channel Swift ke Apple Vision (`VNRecognizeTextRequest`).
- Jangan mengunci versi plugin sebelum memeriksa kompatibilitas iOS deployment target dan Flutter stable.

## 10. UI/UX Requirements

Gaya visual:
- Modern, minimal, premium, tidak ramai.
- Light mode dan dark mode.
- Warna utama emerald/green untuk kondisi positif, merah untuk expense/peringatan, navy/neutral sebagai warna dasar.
- Angka saldo dan nominal harus mudah dibaca.
- Gunakan format `Rp1.000.000`.
- Hindari terlalu banyak grafik di dashboard.

Bottom navigation yang disarankan:
1. Home
2. Transactions
3. Tombol tengah “+” untuk quick action
4. Budget
5. Reports

Wallet dapat diakses dari Dashboard atau menu khusus. Receipt Scan tersedia sebagai salah satu quick action.

Halaman minimum:
- Onboarding / initial setup.
- Dashboard.
- Wallet list + wallet detail + add/edit wallet.
- Transaction list + transaction detail + add/edit transaction.
- Category management.
- Budget overview + monthly budget setup + category limits.
- Receipt camera + preview + OCR review.
- Monthly report + category detail.
- Settings + backup/restore.

## 11. Keamanan, Privasi, dan Backup

- Tidak ada data keuangan keluar dari perangkat pada MVP.
- Simpan database di direktori aplikasi iOS.
- Jangan log nominal, catatan, teks OCR, atau data sensitif ke console pada release build.
- Pertimbangkan enkripsi database bila threat model mengharuskannya; jangan mengklaim database terenkripsi jika belum diterapkan dan diuji.
- Face ID/Touch ID dapat menjadi app lock, bukan pengganti enkripsi database.
- Backup lokal harus terenkripsi bila berisi data keuangan dan foto struk.
- Restore harus memvalidasi format, versi schema, dan integritas relasi.
- Sediakan konfirmasi sebelum menghapus semua data.
- Sediakan export dan backup yang jelas berbeda: export untuk dibaca, backup untuk restore penuh.

## 12. Testing & Acceptance Criteria

### Unit tests
- Saldo wallet untuk income, expense, transfer masuk/keluar.
- Transfer tidak masuk income/expense.
- Transaksi voided tidak memengaruhi saldo.
- Budget total dan kategori.
- Pergantian bulan dan timezone.
- Parser OCR untuk format struk beragam.
- Pembulatan/format Rupiah tanpa floating point.

### Integration tests
- Buat wallet → catat income → catat expense → saldo benar.
- Transfer antar-wallet → saldo kedua wallet benar dan total aset tetap.
- Buat budget → transaksi expense → progress berubah.
- Scan struk → review → simpan → transaksi muncul dan saldo berubah.
- Export PDF/CSV menghasilkan data periode yang benar.
- Backup → hapus data uji → restore → data konsisten.

### Acceptance criteria MVP
1. Aplikasi dapat dibuka dan digunakan tanpa internet.
2. Pengguna dapat membuat minimal dua wallet.
3. Income/expense memperbarui saldo wallet dengan benar.
4. Transfer mengubah saldo dua wallet tanpa mengubah total aset dan total income/expense.
5. Laporan bulanan konsisten dengan transaksi.
6. Budget menghitung expense confirmed saja.
7. OCR berjalan tanpa mengunggah foto.
8. Hasil OCR dapat diedit dan tidak tersimpan sebelum dikonfirmasi.
9. Data tetap tersedia setelah aplikasi ditutup dan dibuka kembali.
10. Backup/restore lokal berhasil dan tervalidasi.

## 13. Tahapan Implementasi untuk Antigravity

### Phase 0 — Project foundation
- Buat Flutter project iOS.
- Setup lint, folder structure, theme, routing, Riverpod.
- Siapkan database Drift dan migration v1.
- Buat design tokens dan reusable widgets.
**Output:** aplikasi dapat dijalankan di iOS Simulator, struktur siap dikembangkan.

### Phase 1 — Wallet & transaction engine
- Implementasi wallet CRUD/archive.
- Implementasi category seed dan custom categories.
- Implementasi income, expense, transfer.
- Implementasi repository, use cases, dan saldo.
- Unit test business rules.
**Output:** pencatatan dan saldo akurat.

### Phase 2 — Dashboard & budget
- Dashboard summary.
- Transaction history dan filter.
- Budget bulanan dan category limits.
- Progress dan local notifications.
- Monthly report dasar.
**Output:** pengguna dapat memantau dan mengontrol pengeluaran.

### Phase 3 — Receipt scanner
- Camera/photo picker.
- Preview, crop/rotate.
- OCR on-device.
- Local receipt parser.
- Review & confirmation flow.
- Attachment storage.
**Output:** struk dapat menjadi draft transaksi yang dikonfirmasi pengguna.

### Phase 4 — Reports, export, backup
- Laporan kategori/wallet.
- Perbandingan bulan.
- Export PDF/CSV.
- Backup/restore lokal tervalidasi.
**Output:** data dapat dianalisis dan dicadangkan.

### Phase 5 — Polish & release readiness
- Accessibility, responsive layouts, dark mode.
- Face ID/Touch ID app lock.
- Error states, empty states, loading states.
- Performance dan database migration tests.
- iOS permission descriptions, app icon, launch screen.
- TestFlight/internal QA.
**Output:** build siap diuji pada perangkat iPhone nyata.

## 14. Instruksi Kerja untuk Antigravity

**Bertindak sebagai senior Flutter engineer dan product-minded mobile architect.** Bangun MyFinance sesuai spesifikasi dokumen ini.

Aturan pengerjaan:
1. Implementasikan secara bertahap sesuai phase; jangan membuat seluruh fitur sekaligus tanpa fondasi.
2. Sebelum coding, tampilkan rencana file, dependency, dan keputusan teknis yang akan digunakan.
3. Jangan menambahkan backend, login, cloud, analytics, atau network upload.
4. Semua fitur utama harus berfungsi offline.
5. Gunakan Riverpod dan Drift; UI tidak boleh berisi SQL atau business logic.
6. Gunakan integer Rupiah dan ledger-based balance calculation.
7. Transfer tidak boleh dihitung sebagai income atau expense.
8. Semua hasil OCR harus masuk halaman review dan memerlukan konfirmasi.
9. Jangan mengarang hasil OCR; field tidak yakin harus ditandai untuk diperiksa.
10. Tulis unit test untuk seluruh aturan perhitungan keuangan.
11. Jalankan `flutter analyze`, seluruh test, dan build iOS setelah tiap fase yang relevan.
12. Jangan menghapus atau mengganti file konfigurasi penting tanpa menjelaskan alasannya.
13. Jika ada keputusan yang ambigu, ajukan pertanyaan singkat sebelum membuat asumsi yang memengaruhi data atau perhitungan.
14. Setelah setiap fase, laporkan file yang dibuat/diubah, fitur selesai, hasil test, dan pekerjaan tersisa.

**Mulai dari Phase 0.** Jangan lanjut ke Phase 1 sebelum fondasi project, routing, theme, database, dan test awal berhasil dijalankan.

---

## 15. Definition of Done

MVP dinyatakan selesai jika:
- Semua acceptance criteria pada bagian 12 lulus.
- Tidak ada error `flutter analyze` yang belum dijelaskan.
- Unit, widget, dan integration tests utama lulus.
- Aplikasi berjalan di iOS Simulator dan setidaknya satu perangkat iPhone nyata.
- Penggunaan aplikasi inti tidak membutuhkan internet.
- Tidak ada data keuangan atau foto struk yang dikirim ke layanan eksternal.
- Dokumentasi setup, database migration, backup/restore, dan cara menjalankan project tersedia.
