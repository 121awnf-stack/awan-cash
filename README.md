# Awan Cash ☁️

Aplikasi pencatatan keuangan pribadi berbasis Android (.apk) yang mengusung filosofi **"Awan"**: super ringan, tampilan bersih bernuansa biru langit, dan **100% Offline-First** untuk menjamin privasi keuangan Anda tanpa server perantara.

---

## 🚀 Fitur yang Tersedia

1. **Dashboard & Analisis:**
   - Kartu Total Kekayaan Bersih (*Net Worth*) dengan gradien awan modern.
   - Ringkasan pemasukan & pengeluaran bulanan.
   - Daftar kartu dompet dengan saldo riil masing-masing.
   - Diagram Donat (*Donut Chart*) proporsi pengeluaran per kategori.
   - Diagram Batang (*Bar Trend Chart*) tren pengeluaran 7 hari terakhir.
   - Daftar transaksi terakhir.

2. **Pencatatan Transaksi Kilat:**
   - 3 Mode: **Pengeluaran**, **Pemasukan**, dan **Transfer Antar Dompet**.
   - Input nominal otomatis terformat Rupiah (IDR) dengan tombol cepat (+10k, +50k, +100k, +500k).
   - Pemilihan kategori dengan ikon warna-warni.
   - Pemilihan dompet sumber & tujuan.
   - Pengambilan foto bukti struk via Kamera atau Galeri.

3. **Manajemen Multi-Dompet:**
   - Mendukung Uang Tunai, Rekening Bank, dan E-Wallet (GoPay, OVO, Dana, dll.).
   - Atur saldo awal, warna kartu, dan ikon dompet.

4. **Anggaran Bulanan (Budgeting):**
   - Tetapkan batas maksimal pengeluaran per kategori setiap bulan.
   - Indikator progres bar visual (Hijau: aman, Kuning: >75%, Merah: Over-budget).

5. **Keamanan & Privasi:**
   - Kunci PIN 4-6 digit.
   - Buka kunci dengan sensor Biometrik (Sidik Jari / Wajah) melalui `local_auth`.

6. **Ekspor & Cadangan Data:**
   - Ekspor riwayat ke file **Excel (`.xlsx`)** dan **CSV**.
   - Cadangkan seluruh database ke file JSON.
   - Pulihkan data kapan saja dari file cadangan.

---

## 🛠️ Cara Menjalankan & Membangun File .APK

Pastikan komputer Anda sudah terpasang **Flutter SDK** dan **Android SDK / Android Studio**.

### 1. Masuk ke direktori proyek
```bash
cd awan_cash
```

### 2. Unduh paket dependensi
```bash
flutter pub get
```

### 3. Jalankan aplikasi di Emulator atau HP Android
```bash
flutter run
```

### 4. Build file installer `.apk` siap pakai
```bash
# Build APK rilis universal
flutter build apk --release
```
File installer `.apk` yang dihasilkan akan berada di direktori:
`awan_cash/build/app/outputs/flutter-apk/app-release.apk`
