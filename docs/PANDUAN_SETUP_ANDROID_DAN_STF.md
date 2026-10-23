# 📱 Panduan Lengkap: Setup Perangkat Android, Terminal ADB & STF Web

Dokumen ini berisi panduan resmi untuk menghubungkan perangkat Android fisik, instalasi APK melalui terminal ADB, mengatasi masalah perangkat tidak terdeteksi, serta panduan mengakses dan mengontrol HP melalui web menggunakan **STF (Smartphone Test Farm)**.

---

## 📌 1. Cara Menghubungkan HP ke Komputer (ADB)

### Langkah di HP Android (Infinix / Lainnya):
1. **Aktifkan Opsi Pengembang (Developer Options):**
   - Buka **Pengaturan (Settings)** -> **Ponsel Saya (My Phone)**.
   - Cari **Nomor Bentukan (Build Number)**, lalu ketuk sebanyak **7 kali berturut-turut** hingga muncul pesan *"Anda sekarang adalah seorang pengembang!"*.
2. **Aktifkan USB Debugging:**
   - Masuk ke **Pengaturan** -> **Sistem** -> **Opsi Pengembang (Developer Options)**.
   - Aktifkan toggle **Debugging USB (USB Debugging)**.
   - Jika ada opsi **Instal via USB** (*Install via USB*) atau **Debugging USB (Pengaturan Keamanan)**, aktifkan juga.
3. **Colokkan Kabel USB ke Komputer:**
   - Tarik bilah notifikasi di HP dari atas ke bawah.
   - Cari notifikasi **"Mengisi daya perangkat ini lewat USB"**.
   - Ubah dari *"Hanya isi daya / Tidak ada transfer data"* menjadi **"Transfer File / Android Auto" (MTP)**.
4. **Otorisasi Komputer:**
   - Di layar HP akan muncul pop-up: *"Izinkan debugging USB dari komputer ini?"*.
   - Centang **"Selalu izinkan dari komputer ini"** (*Always allow from this computer*), lalu ketuk **Izinkan (Allow)**.

---

## 🔍 2. Troubleshooting: Mengapa `adb devices` Kosong?

Jika Anda menjalankan:
```powershell
adb devices
# Output:
# List of devices attached
# (kosong)
```

Berikut penyebab dan solusinya:

| Penyebab | Ciri-Ciri | Solusi |
|---|---|---|
| **Typo Perintah `-1` vs `-l`** | Mengetik `adb devices -1` (angka satu) | Gunakan huruf L kecil: `adb devices -l` (singkatan dari *long output*). |
| **Kabel USB Lepas / Longgar** | Windows PnP mencatat `CM_PROB_PHANTOM` | Cabut dan colokkan kembali kabel USB dengan rapat. Coba gunakan port USB lain di motherboard laptop/PC. |
| **Kabel Hanya Mendukung Charging** | HP mengisi daya tetapi tidak ada notifikasi USB MTP | Ganti dengan kabel data USB yang mendukung transfer data (bukan kabel charger saja). |
| **Mode USB Masih "Hanya Isi Daya"** | HP tidak membuka jalur data ADB | Buka notifikasi HP, ubah mode USB menjadi **"Transfer File (MTP)"**. |
| **USB Debugging Belum Aktif / Belum Diizinkan** | Device tidak muncul atau status `unauthorized` | Pastikan toggle Debugging USB aktif di Opsi Pengembang dan tekan tombol "Izinkan" pada layar HP. |
| **ADB Server Perlu Di-refresh** | ADB daemon hang / freeze | Jalankan: `adb kill-server` lalu `adb devices`. |

---

## 🚀 3. Perintah Terminal untuk Instalasi & Kontrol APK

Lokasi APK rilis yang siap dipasang:
> `D:\Dev\project\webapp\LalapDart\lalapan_mobile\build\app\outputs\flutter-apk\app-release.apk`

### Perintah Penting ADB:

```powershell
# 1. Cek apakah HP sudah terdeteksi (gunakan huruf 'L' kecil)
adb devices -l

# 2. Instal APK (menimpa versi lama tanpa hapus data)
adb install -r "D:\Dev\project\webapp\LalapDart\lalapan_mobile\build\app\outputs\flutter-apk\app-release.apk"

# 3. Instal APK + otomatis izinkan akses Kamera & Dokumen
adb install -r -g "D:\Dev\project\webapp\LalapDart\lalapan_mobile\build\app\outputs\flutter-apk\app-release.apk"

# 4. Jalankan aplikasi Lalapan langsung ke layar HP
adb shell am start -n com.lalapan.mobile/.MainActivity

# 5. Hentikan paksa aplikasi (Force Close)
adb shell am force-stop com.lalapan.mobile

# 6. Lihat log error runtime secara langsung (logcat)
adb logcat -s Flutter:* AndroidRuntime:*

# 7. Hapus aplikasi (Uninstall) - menggunakan Nama Package:
adb uninstall com.lalapan.mobile
```

> [!WARNING]
> **Perbedaan Penting (Jangan Tertukar!):**
> - **`adb uninstall`** menggunakan **Nama Package** (contoh: `com.lalapan.mobile`), karena aplikasi sudah terdaftar di sistem Android.
> - **`adb install`** WAJIB menyertakan **Path File Fisik APK** yang berakhiran `.apk`.
>   - ❌ **SALAH**: `adb install -r com.lalapan.mobile` (Akan menghasilkan error: *filename doesn't end .apk*).
>   - ❌ **SALAH**: `adb install -r` (Tanpa nama file).
>   - ✅ **BENAR**: `adb install -r "D:\Dev\project\webapp\LalapDart\lalapan_mobile\build\app\outputs\flutter-apk\app-release.apk"`

---

## 🌐 4. Panduan Menjalankan STF (Smartphone Test Farm) di Web

STF memungkinkan Anda menampilkan layar HP dan mengontrolnya secara remote (klik, scroll, ketik teks, drag-and-drop APK) langsung di browser web.

### Langkah 1: Jalankan ADB Server Terbuka untuk Docker
Docker STF berjalan di Linux WSL2, sehingga ADB daemon di Windows wajib menerima koneksi dari network Docker (`0.0.0.0`):
```powershell
# Matikan instance lama
adb kill-server

# Jalankan ADB server dengan flag -a (listen all interfaces) di background
Start-Process adb -ArgumentList "-a", "nodaemon", "server" -WindowStyle Hidden

# Pastikan port 5037 aktif mendengarkan:
netstat -ano | findstr 5037
# Harus ada: TCP 0.0.0.0:5037 LISTENING
```

### Langkah 2: Nyalakan Container STF & RethinkDB
```powershell
docker start rethinkdb
docker start stf
```

### Langkah 3: Buka STF di Browser Web
1. Buka peramban (Chrome / Edge / Firefox) dan akses:
   👉 **[http://127.0.0.1:7100](http://127.0.0.1:7100)**
2. **Login**: Masukkan nama dan email sembarang (contoh: Nama: `admin`, Email: `admin@local`).
3. Pada tab **Devices**, Anda akan melihat HP Anda (**Infinix NOTE 50 Pro / Infinix X6855**) dengan tombol hijau **"Use"**.
4. Klik tombol **"Use"**:
   - Layar HP Anda akan muncul secara *live streaming* interaktif.
   - Anda dapat mengoperasikan aplikasi, klik tombol, scroll, dan mengetik keyboard.
   - Anda juga dapat langsung **menyeret (drag-and-drop) file `app-release.apk` ke layar STF** untuk memasang aplikasi secara instan!
