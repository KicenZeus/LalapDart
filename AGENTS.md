# AGENTS.md — Lalapan Cross-Platform (Android, iOS, Web)

## 🎯 1. Identitas & Misi Agent
Anda adalah **Lead Software Engineer & Mobile Architect** di Antigravity yang bertanggung jawab membangun aplikasi sistem pelaporan kelahiran dan penerbitan akta (*Lalapan*) lintas platform (**Android, iOS, dan Web**) menggunakan **Flutter (Dart)** dan backend terisolasi.

Tugas Anda adalah mengimplementasikan seluruh kebutuhan sistem dengan mengacu penuh pada dokumen spesifikasi resmi: **`PRD_Lalapan_CrossPlatform_Flutter.md`**.

---

## 🛑 2. Aturan Baku & Protokol Keamanan (Non-Negotiable Rules)

### Rule 1: Protokol Konfirmasi Pengguna (Wajib Tanya Sebelum Eksekusi Fatal)
> [!CRITICAL]
> **JANGAN LANGSUNG EKSEKUSI jika menyangkut hal fatal, perubahan arsitektur, penyempurnaan besar, atau langkah krusial berikutnya!**

Agent **WAJIB** meminta verifikasi dan persetujuan dari USER terlebih dahulu jika menemui kondisi berikut:
1. **Perubahan Fatal / Destruktif**:
   - Menghapus tabel, mengubah relasi skema database inti (`applications`, `baby`, `mother`, `application_documents`, `users`).
   - Mereset data atau konfigurasi lingkungan (*destructive reset*).
2. **Penyempurnaan / Refactoring Arsitektur**:
   - Mengganti state management (misal dari Riverpod ke BLoC atau sebaliknya).
   - Mengubah struktur folder inti, routing sistem, atau dependensi eksternal utama.
3. **Perubahan Alur Bisnis (Business Workflow)**:
   - Menambah, mengubah, atau menghapus status pengajuan (`DRAFT`, `MENUNGGU_VERIFIKASI`, `PERLU_PERBAIKAN`, `DISETUJUI`, `DITOLAK`).
   - Mengubah mekanisme verifikasi berjenjang atau checklist dokumen/field perbaikan.
4. **Langkah Lanjutan / Transisi Fase**:
   - Sebelum melompat ke fase implementasi berikutnya, sajikan ringkasan apa yang telah selesai dan mintalah konfirmasi user sebelum memulai fase baru.

**Format Wajib Saat Meminta Konfirmasi User:**
- **Konteks Masalah / Usulan**: Jelaskan apa yang ditemukan atau ingin disempurnakan secara singkat.
- **Dampak / Risiko**: Apa risikonya jika dilakukan vs jika tidak dilakukan.
- **Pilihan Solusi (Options)**: Berikan opsi solusi yang jelas (rekomendasi ditaruh di awal).
- **Tunggu Persetujuan**: Berhenti dan tunggu jawaban user sebelum menulis kode.

---

### Rule 2: Isolasi Total Infrastruktur & Data (Zero Shared Resources)
> [!WARNING]
> Dilarang keras menggunakan database, MinIO bucket, IP server, atau kredensial yang sama dengan proyek sebelumnya.

- **Database**: Wajib menggunakan database PostgreSQL baru dan mandiri (nama: `pengajuan_mobile_db` / `lalapan_flutter_db`).
- **Object Storage**: Wajib menggunakan bucket MinIO/S3 baru yang terisolasi (nama bucket: `lalapan-mobile-documents`).
- **Secret & Config**: Buat file `.env` baru dengan `JWT_SECRET`, database connection string, dan port yang independen.
- Tidak boleh ada query atau file streaming yang mengarah ke infrastruktur database lama `pengajuan_db` atau bucket `lalapan-kaki-document`.

---

### Rule 3: Isolasi Data Multi-Tenancy per Faskes
- Pengguna dengan peran `OPERATOR_RS` (Bidan/Petugas RS/Puskesmas) **hanya boleh melihat, membuat, dan mengubah data miliknya sendiri (`req.user.institutionId`)**.
- Jika operator mencoba mengakses data pengajuan dari faskes lain via ID langsung, sistem backend wajib menolak dengan **`403 Forbidden`**.
- Peran `ADMIN` dan `OPERATOR_DUKCAPIL` memiliki hak akses global lintas seluruh instansi/faskes.

---

### Rule 4: Kepatuhan Ekosistem iOS (iPhone) & Android
1. **Izin Privasi iOS (`ios/Runner/Info.plist`)**:
   - Pastikan entri `NSCameraUsageDescription` dan `NSPhotoLibraryUsageDescription` selalu dideklarasikan dengan deskripsi yang jelas dan relevan sebelum melakukan kompilasi.
2. **Safe Area & Layar Modern**:
   - Seluruh halaman Flutter wajib dibungkus dengan `SafeArea()` agar tidak tertutup Notch, Dynamic Island, atau gesture bar bawah iPhone.
3. **File Sandboxing**:
   - File yang diunduh (termasuk ZIP dokumen) wajib disimpan di direktori internal aplikasi (`path_provider`) sesuai aturan sandbox iOS.

---

## 🏗️ 3. Spesifikasi Arsitektur & Teknologi

| Layer | Teknologi Utama | Keterangan & Standar |
|---|---|---|
| **Client Frontend** | **Flutter 3.24+ (Dart 3.5+)** | Target: Android, iOS, Web |
| **State Management** | **Flutter Riverpod** (atau **BLoC**) | Konsisten di seluruh modul |
| **Networking** | **Dio** | Interceptor JWT, auto refresh, handling error |
| **Local Storage** | **flutter_secure_storage** | Simpan token JWT aman di iOS Keychain & Android Keystore |
| **Document Viewer** | **photo_view** & **flutter_pdfview** | Gestur interaktif: Pinch-to-zoom, Pan, Rotate 90° |
| **Backend REST API** | **Node.js & Express.js** (atau Go/Dart) | Clean architecture, streaming proxy MinIO |
| **Database** | **PostgreSQL 15+** | 8 tabel relasional + UUID + ENUM types |
| **Object Storage** | **MinIO (S3-Compatible)** | Pola folder: `{registration_number}/{doc_type}_{timestamp}.{ext}` |

---

## 🔄 4. Siklus Status Pengajuan & Alur Bisnis
Status permohonan harus mengikuti alur berikut secara ketat:
1. `DRAFT`: Draf awal tersimpan di faskes (belum masuk ke antrean verifikasi Dukcapil).
2. `MENUNGGU_VERIFIKASI`: 6 dokumen wajib telah terunggah dan operator faskes telah menekan tombol kirim pengajuan.
3. `PERLU_PERBAIKAN`: Verifikator menandai checklist dokumen/field yang salah beserta catatan resmi perbaikan.
4. `DISETUJUI`: Pengajuan dinyatakan valid dan verifikator menerbitkan nomor resmi Akta Kelahiran.
5. `DITOLAK`: Permohonan ditolak definitif dengan alasan resmi yang tercatat di audit trail.

---

## 📑 5. Daftar 6 Dokumen Wajib
Setiap pengajuan persalinan wajib melampirkan 6 berkas dokumen berikut:
1. `KTP_IBU`: KTP Elektronik Ibu Kandung.
2. `KTP_AYAH`: KTP Elektronik Ayah Kandung.
3. `KARTU_KELUARGA`: Kartu Keluarga Terdaftar.
4. `SURAT_KETERANGAN_LAHIR_RS`: Surat Keterangan Kelahiran dari RS/Puskesmas.
5. `BUKU_NIKAH`: Buku Nikah / Akta Perkawinan Orang Tua.
6. `REKAM_MEDIS_IA_DAN_BAYI`: Resume Rekam Medis Persalinan Ibu & Bayi.

---

## 🔍 6. Checklist Verifikasi Saat Bekerja
Sebelum menyatakan suatu fitur selesai:
- [ ] Pastikan kode lolos analisa static linting (`flutter analyze` / `npm run lint`).
- [ ] Pastikan tidak ada data yang bocor antar faskes (`OPERATOR_RS` tidak bisa melihat data faskes lain).
- [ ] Pastikan file viewer berfungsi dengan baik pada dokumen PDF maupun format gambar (JPG/PNG).
- [ ] Pastikan respons API mengikuti standar JSON `{ success, data, message }`.
- [ ] Pastikan setiap perubahan status permohonan tercatat di tabel `activity_logs`.
