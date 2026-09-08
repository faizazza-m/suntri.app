# e-Suntri 📱

Aplikasi sistem manajemen santri terpadu (MTRQ) yang dibangun menggunakan Flutter. Aplikasi ini dirancang untuk memudahkan berbagai pemangku kepentingan (Mudir, Musyrif, Guru, dan Wali Santri) dalam memantau dan mengelola kegiatan akademik, hafalan, serta absensi santri.

## 🌟 Fitur Utama

Aplikasi ini memiliki beberapa antarmuka (Dashboard) yang disesuaikan dengan peran pengguna:
- **Dashboard Mudir**: Pantauan umum, rekap data, dan grafik perkembangan.
- **Dashboard Admin**: Pengelolaan data master (jika diakses via mobile/web).
- **Dashboard Musyrif**: Pencatatan setoran hafalan harian, absensi halaqoh, dan laporan kegiatan asrama.
- **Dashboard Guru/Akademik**: Jadwal mengajar dan penilaian akademis.
- **Dashboard Wali Santri**: Memantau perkembangan hafalan, nilai rapor, dan laporan mingguan anak secara *real-time*.
- **Sistem Notifikasi**: Pengingat otomatis (jam 06:00, 10:00, 13:00) untuk absen dan setoran santri.

## 🛠️ Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev/)
- **Backend / Database**: Supabase
- **Fitur Tambahan**: Local Notifications, Timezone, Printing/PDF, dsb.

## 🚀 Cara Menjalankan (Setup Project)

Jika Anda ingin menjalankan atau berkontribusi pada proyek ini secara lokal, ikuti langkah-langkah berikut:

1. **Clone Repository**
   ```bash
   git clone https://github.com/faizazza-m/suntri.app.git
   cd e-suntri
   ```

2. **Install Dependencies**
   Jalankan perintah ini untuk mengunduh semua library yang dibutuhkan:
   ```bash
   flutter pub get
   ```

3. **Pengaturan Environment (.env)**
   Aplikasi ini membutuhkan file konfigurasi rahasia (`.env`) untuk bisa terhubung ke Supabase.
   - Buat file bernama `.env` di direktori utama proyek (sejajar dengan `pubspec.yaml`).
   - Isi file `.env` dengan kredensial API (tanyakan kepada pemilik repositori untuk detail kuncinya).
   - *Catatan: File `.env` sudah masuk ke dalam `.gitignore` sehingga aman dan tidak akan terpublikasi.*

4. **Jalankan Aplikasi**
   Setelah semua siap, jalankan aplikasi di perangkat atau emulator:
   ```bash
   flutter run
   ```

## 📦 Build untuk Produksi (Release)

Untuk menghasilkan file APK (Android) yang siap dibagikan/di-install:
```bash
flutter build apk --release
```
File APK akan berada di dalam folder `build/app/outputs/flutter-apk/`.

---
*Dikembangkan dengan ❤️ untuk kemajuan pendidikan Islam.*
