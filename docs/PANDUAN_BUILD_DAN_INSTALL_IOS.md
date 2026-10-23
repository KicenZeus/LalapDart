# 🍏 Panduan Lengkap Build & Install Aplikasi Lalapan di iOS (iPhone / iPad)

Dokumen ini menjelaskan tata cara mengompilasi dan memasang aplikasi **Lalapan Mobile** ke perangkat iOS (iPhone/iPad), baik jika Anda memiliki komputer Mac maupun jika Anda bekerja dari PC **Windows**.

---

## 📌 Ketentuan Dasar Ekosistem Apple
> [!IMPORTANT]
> Apple mewajibkan **macOS** dan **Xcode** untuk mengompilasi kode sumber native iOS (*Objective-C / Swift / CocoaPods*). Kompilasi langsung file `.ipa` secara offline tidak dapat dilakukan dari dalam kernel Windows.

Namun, Anda memiliki **3 metode resmi & praktis** berikut:

---

## 🚀 Metode 1: Jika Memiliki Komputer Mac / MacBook (Cara Standar & Termudah)

Jika Anda memiliki akses ke MacBook atau Mac mini:

### 1. Salin Proyek ke Mac
Clone repository atau salin folder proyek `LalapDart` ke Mac Anda.

### 2. Install Dependensi CocoaPods & Flutter
Buka terminal Mac di dalam folder `lalapan_mobile`:
```bash
cd lalapan_mobile
flutter pub get
cd ios
pod install
cd ..
```

### 3. Konfigurasi Signing di Xcode (Gratis / Free Apple ID)
1. Buka file workspace di Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Di panel kiri Xcode, klik **Runner** (paling atas).
3. Pilih tab **Signing & Capabilities**.
4. Centang **"Automatically manage signing"**.
5. Pada dropdown **Team**:
   - Jika belum ada, klik *Add an Account...* lalu login menggunakan **Apple ID biasa (gratis)** Anda.
   - Pilih Personal Team Anda.
6. Pada **Bundle Identifier**, ubah sedikit jika perlu (contoh: `com.lalapan.mobile.app`).

### 4. Jalankan ke iPhone Fisik
1. Hubungkan iPhone ke Mac dengan kabel data USB.
2. Pada iPhone, pilih **"Trust This Computer"** dan masukkan passcode.
3. Di bagian atas Xcode, pilih target device: **Nama iPhone Anda** (bukan Simulator).
4. Tekan tombol **Run (Play ▶)** di pojok kiri atas Xcode, atau jalankan via terminal:
   ```bash
   flutter run -d ios --release
   ```
5. **Aktivasi Izin di iPhone**:
   - Saat pertama kali terpasang, aplikasi belum bisa dibuka sebelum diberi izin.
   - Buka iPhone: **Settings > General > VPN & Device Management**.
   - Pilih akun Apple ID Anda di bawah *Developer App*, lalu klik **"Trust [Nama Akun Anda]"**.
   - Aplikasi Lalapan siap dibuka dan digunakan!

---

## ☁️ Metode 2: Tanpa Komputer Mac (Build via GitHub Actions Cloud)

Jika Anda hanya memiliki PC Windows, gunakan **GitHub Actions** (Runner macOS gratis dari GitHub) untuk mengompilasi file `.ipa`:

### 1. Workflow GitHub Actions
File workflow telah disediakan di `.github/workflows/build_ios.yml`:
```yaml
name: Build iOS IPA

on:
  workflow_dispatch: # Dapat dipicu manual dengan 1 klik tombol di web GitHub

jobs:
  build:
    runs-on: macos-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        run: |
          cd lalapan_mobile
          flutter pub get
          cd ios
          pod install

      - name: Build iOS Application
        run: |
          cd lalapan_mobile
          flutter build ios --release --no-codesign

      - name: Package to IPA (Payload packaging)
        run: |
          cd lalapan_mobile/build/ios/iphoneos
          mkdir Payload
          cp -r Runner.app Payload/
          zip -r Lalapan_unsigned.ipa Payload

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: Lalapan-iOS-IPA
          path: lalapan_mobile/build/ios/iphoneos/Lalapan_unsigned.ipa
```

### 2. Cara Mengunduh Hasil Build:
1. Push repository Anda ke GitHub.
2. Buka tab **Actions** di repo GitHub Anda.
3. Pilih workflow **Build iOS IPA** lalu klik **Run workflow**.
4. Tunggu proses selesai (~5-8 menit).
5. Unduh file `Lalapan-iOS-IPA.zip` dari bagian **Artifacts**.

---

## 📲 Metode 3: Install File `.ipa` ke iPhone dari Windows via Sideloadly

Setelah memiliki file `.ipa` (dari GitHub Actions):

1. **Unduh Sideloadly di Windows**:
   - Download gratis dari website resmi: [sideloadly.io](https://sideloadly.io/).
   - Install juga **iTunes** dan **iCloud for Windows** (versi non-Microsoft Store, link tersedia di halaman web Sideloadly).
2. **Hubungkan iPhone**:
   - Colokkan iPhone ke laptop Windows via kabel USB.
   - Buka aplikasi Sideloadly. iPhone Anda akan otomatis terdeteksi di kolom *iDevice*.
3. **Pilih File `.ipa` & Masukkan Apple ID**:
   - Drag & drop file `Lalapan_unsigned.ipa` ke kotak berlogo IPA di Sideloadly.
   - Masukkan alamat email Apple ID Anda di kolom *Apple ID*.
4. **Klik "Start"**:
   - Sideloadly akan meminta password Apple ID (dan kode 2FA di layar iPhone jika aktif) untuk menandatangani sertifikat pengembang gratis selama 7 hari.
5. **Selesai**:
   - Buka iPhone: **Settings > Privacy & Security > Developer Mode** (nyalakan Developer Mode jika menggunakan iOS 16+).
   - Masuk ke **Settings > General > VPN & Device Management**, klik akun Apple ID Anda, lalu klik **Trust**.
   - Aplikasi Lalapan langsung aktif di iPhone Anda!

---

## 🌐 Metode 4: PWA (Progressive Web App) di Safari iPhone (Instan Tanpa Install File)

Jika Anda ingin langsung menguji aplikasi di iPhone dalam 1 menit tanpa perlu build IPA:

1. Pastikan iPhone dan PC Windows Anda terhubung ke jaringan **Wi-Fi yang sama**.
2. Cari IP lokal laptop Windows Anda (misal: `192.168.1.50`).
3. Di iPhone, buka browser **Safari** dan ketik alamat:
   ```text
   http://192.168.1.50:8090
   ```
4. Di Safari, tekan tombol **Share** (ikon kotak dengan panah ke atas di bagian bawah layar).
5. Gulir ke bawah dan pilih **"Add to Home Screen"** (*Tambahkan ke Layar Utama*).
6. Beri nama **"Lalapan"** lalu tekan **Add**.
7. Ikon Lalapan akan muncul di layar utama iPhone Anda dan berjalan fullscreen layaknya aplikasi native iOS!
