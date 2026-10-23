# 🎨 DOKUMEN SPESIFIKASI DESAIN & PROMPT MASTER AI STITCH
## Proyek: Lalapan (Sistem Pelaporan Kelahiran & Penerbitan Akta Kelahiran Lintas Platform)
**Gaya Desain:** Simple, Clean, Modern Adaptive Glassmorphism (Frosted Glass UI)  
**Target Platform:** Web (Desktop/Tablet) & Mobile (Android/iOS)  
**Tema:** Adaptive Glass (Light Glass Default + Dark Glass OLED/Night Mode)  
**Slot Background Khusus:** Landing Page, Halaman Login, dan Cek Status Publik  
**Status Dokumen:** Siap Pakai untuk AI Stitch / Google Stitch / UI Generator

---

## 📌 1. MASTER PROMPT AI STITCH (Sekali Copy-Paste untuk Seluruh Aplikasi)

> **Instruksi Penggunaan:** Salin seluruh teks di dalam blok kode di bawah ini, lalu tempelkan (*paste*) langsung ke input prompt AI Stitch untuk men-generate keseluruhan arsitektur UI aplikasi.

```text
Create a complete, modern, high-fidelity UI design system and screen flow for "LALAPAN" — an Indonesian Government & Hospital Cross-Platform Application (Web & Mobile) for Digital Birth Reporting and Birth Certificate Issuance (Dinas Kependudukan dan Pencatatan Sipil / Disdukcapil & Rumah Sakit / Puskesmas).

### 🌟 DESIGN AESTHETIC: ADAPTIVE SIMPLE GLASSMORPHISM
- Style: Minimalist Frosted Glass (Glassmorphism). Ultra-sleek, clean, elegant, and uncluttered.
- Theme System: Adaptive Glass:
  * Light Frosted Glass (Default Day Mode): background rgba(255, 255, 255, 0.78), backdrop-filter blur(20px), border 1px solid rgba(255, 255, 255, 0.45), typography #0F172A.
  * Dark Frosted Glass (Night / OLED Mode): background rgba(15, 23, 42, 0.70), backdrop-filter blur(20px), border 1px solid rgba(255, 255, 255, 0.12), typography #F8FAFC.
- Ambient Elevation: Soft ambient floating drop shadows (box-shadow: 0 8px 32px 0 rgba(15, 23, 42, 0.08)) with 16px - 24px corner radius.
- Custom Photographic Backgrounds: Seamlessly layered behind floating glass panels for 3 dedicated pages:
  1. Landing Page: Warm family & newborn maternity photography with subtle dark scrim (rgba(15, 23, 42, 0.40) to rgba(15, 23, 42, 0.75)).
  2. Petugas Login: Modern architectural healthcare / civic administration background with soft focus blur.
  3. Cek Status Publik: Clean reassuring community / civic backdrop with interactive glass timeline overlay.
- Visual Hierarchy: Multi-layered Z-axis (Layer 0: Full-bleed Hero Photo; Layer 1: Contrast Scrim; Layer 2: Main Frosted Glass Panels; Layer 3: Floating Action Chips & Modals).

### 🎨 COLOR PALETTE & DESIGN TOKENS
- Primary Brand: Royal Navy Blue (#1E40AF) & Deep Slate Navy (#0F172A) — conveys government authority and institutional trust.
- Accent & Highlights: Vibrant Cyan / Teal (#06B6D4 / #0D9488) — gives a fresh, modern, healthcare-friendly touch.
- Status Colors:
  * MENUNGGU_VERIFIKASI: Warm Amber (#F59E0B) with soft amber frosted glass pill.
  * PERLU_PERBAIKAN: Crimson Coral (#EF4444) with warning glass tag.
  * DISETUJUI: Vibrant Emerald Green (#10B981) with success glow.
  * DRAFT: Cool Slate (#64748B) with neutral frosted badge.
- Typography: Plus Jakarta Sans / Inter. Clean geometric grotesque sans-serif with crisp hierarchy (H1 Bold 32px, H2 SemiBold 24px, Body Regular 14-16px, Micro/Badge 11-12px Medium).

---

### 📱 LIST OF ALL CORE SCREENS TO GENERATE:

#### 1. LANDING PAGE (Web Desktop & Mobile Responsive)
- Background: Full-bleed custom image with responsive dark/light scrim gradient.
- Header: Floating glass navbar with Logo ("LALAPAN"), navigation links (Beranda, Cek Status, Panduan Faskes, Login Petugas), and a primary frosted glass CTA button ("Masuk Petugas").
- Hero Section: Large bold headline: "Penerbitan Akta Kelahiran Bayi Baru Lahir Cepat, Terintegrasi & Digital".
- Quick Search Box: Floating glass search card with prompt "Lacak Status Akta Kelahiran Bayi Anda".
- Feature Highlights: 3 floating glass cards highlighting "Integrasi 29 Faskes", "Validasi 6 Berkas Resmi", and "Unduh Akta Digital Langsung".

#### 2. CEK STATUS PUBLIK (/tracking)
- Background: Custom civic/community background image with soft atmospheric glass overlay.
- Search Module: Prominent glass search bar with input: "Masukkan NIK Ibu Kandung (16 Digit) atau Nomor Registrasi (REG-...)".
- Live Status Result: When searched, reveal an elegant 4-step vertical/horizontal glass timeline tracker:
  1. [✓] Draf Pengajuan Dibuat oleh Faskes (RSUD dr. Soedono)
  2. [⏳] Menunggu Verifikasi Berkas Dukcapil
  3. [!] Perlu Perbaikan Dokumen (jika ada catatan revisi)
  4. [⭐] Akta Kelahiran Resmi Diterbitkan (menampilkan Nomor Akta resmi & tombol unduh)
- Summary Card: Glass card showing Baby's birth date, mother's name, registered hospital, and current processing timestamp.

#### 3. PETUGAS LOGIN SCREEN (/login)
- Background: Custom modern hospital/civic architectural background with depth-of-field blur.
- Login Card: Centered floating frosted glass card with glowing border.
- Elements: App seal icon, title "Portal Layanan Kelahiran Terpadu", Role Segmented Tabs (Operator Faskes / Verifikator Dukcapil / Administrator), Username/Email input, Password input with eye toggle, "Ingat Saya" checkbox, and a prominent vibrant blue gradient button "Masuk ke Sistem".
- Server Badge: Discreet bottom glass chip showing current API connection status (e.g., "● Server Terhubung: 127.0.0.1:5055").

#### 4. MULTI-ROLE OPERATIONAL DASHBOARD (/dashboard)
- Layout: Glass sidebar navigation (Desktop) / Glass Floating Bottom Navigation Bar (Mobile).
- Top Bar: Institution Name Badge (e.g., "RSUD dr. Soedono Madiun" or "Disdukcapil Kota"), User Profile Avatar, Notification Bell with unread counter.
- Metrics Row: 4 sleek glass KPI cards with subtle neon accent borders:
  1. Total Pengajuan
  2. Menunggu Verifikasi (Amber icon)
  3. Perlu Perbaikan (Red icon)
  4. Akta Selesai / Disetujui (Emerald icon)
- Quick Action Bar: Primary button "+ Buat Pengajuan Kelahiran Baru" (for Faskes) or "Mulai Verifikasi Antrean" (for Dukcapil).
- Data Table / Card Feed: Glass card list showing recent birth reports with Baby Name, Mother NIK, Date, Submitter Faskes, Status Badge, and Action buttons (Detail, Edit, Cetak).

#### 5. 3-STEP BIRTH REGISTRATION WIZARD (/applications/new)
- Top Indicator: Stepper with 3 frosted glass steps (Step 1: Data Bayi -> Step 2: Data Orang Tua -> Step 3: Unggah 6 Dokumen).
- Step 1 (Bayi): Clean form fields inside glass container (Nama Bayi, Jenis Kelamin segmented buttons, Tanggal Lahir picker, Jam Lahir, Berat Badan (gram), Panjang Badan (cm), Jenis Kelahiran Tunggal/Kembar).
- Step 2 (Orang Tua): Two-column glass sub-cards (Data Ibu Kandung: NIK, Nama Lengkap, Tanggal Lahir; Data Ayah Kandung: NIK, Nama Lengkap, Tanggal Lahir, Nomor Kartu Keluarga, Nomor Telepon/WhatsApp).
- Step 3 (6 Dokumen Wajib): Grid of 6 interactive glass upload tiles:
  1. KTP Ibu Kandung
  2. KTP Ayah Kandung
  3. Kartu Keluarga (KK)
  4. Surat Keterangan Lahir RS
  5. Buku Nikah / Akta Perkawinan
  6. Rekam Medis Persalinan
  Each tile features drag-and-drop / camera capture buttons, file preview thumbnail, status chip ("Terunggah / Belum"), and replace/remove actions.
- Bottom Floating Bar: Back button & "Kirim Pengajuan ke Dukcapil" button with confirmation modal.

#### 6. INTERACTIVE DOCUMENT VIEWER & INSPECTOR MODAL
- Full-screen glass modal overlay over transparent scrim.
- Document Canvas: High-fidelity document preview (supporting PDF and high-res JPEG/PNG images).
- Floating Glass Toolbar: Zoom In (+), Zoom Out (-), Rotate 90° clockwise, Pan mode toggle, Download file, and Fullscreen toggle.
- Bottom Inspection Strip: Thumbnails of all 6 uploaded documents for rapid 1-click switching.

#### 7. DISDUKCAPIL VERIFICATION STUDIO (/verification/:id)
- Split-Screen Layout (Web Desktop) or Tabbed Segment (Mobile):
  * Left Panel: Identity & Form Comparison Card (Data Bayi, Data Orang Tua, NIK matching status).
  * Right Panel: Document Review Viewer with per-document Checklist:
    - [x] Dokumen Sah & Terbaca
    - [ ] Dokumen Buram / Butuh Perbaikan (reveals inline note input: "Contoh: Halaman 2 Buku Nikah terpotong").
- Bottom Action Dock:
  * "Minta Perbaikan" button (opens revision summary modal with checklist).
  * "Tolak Pengajuan" button (with official rejection reason).
  * "Setujui & Terbitkan Akta" vibrant emerald button (opens dialog to input / auto-generate official Akta Kelahiran Number).

#### 8. ADMIN MANAGEMENT CONSOLE (/admin)
- Glass management tables for:
  * Manajemen Pengguna: List of users, Institution assignment, Role chips (OPERATOR_RS, OPERATOR_DUKCAPIL, ADMIN), status toggle (Aktif/Nonaktif), "+ Tambah Petugas" dialog.
  * Direktori 29 Faskes: Searchable glass directory of seeded Hospitals & Puskesmas with code, address, contact, and active operator count.
  * Audit Trail: Chronological glass feed of system activities (who created, verified, or approved applications with timestamps).

Ensure all components have clear hover/active microinteractions, generous spacing, high legibility, and mobile-friendly touch targets (minimum 48x48px).
```

---

## 🧩 2. PROMPT MODULAR (Spesifik per Halaman untuk AI Stitch)

Jika Anda ingin men-generate UI per halaman satu-persatu di AI Stitch untuk detail yang lebih tajam dan fokus, gunakan modul prompt di bawah ini:

### 📄 Modul 1: Landing Page
```text
Design a responsive Adaptive Glassmorphism Landing Page for "Lalapan" birth certificate system.
- Background: Fullscreen photo background (warm family/baby theme) with a smooth dark/light adaptive gradient scrim (rgba(15,23,42,0.60)).
- Top Navigation: Floating glass header with logo, menu links (Beranda, Cek Status, Panduan, Kontak), and "Portal Petugas" login button.
- Hero Section: High-impact typography "Layanan Pelaporan Kelahiran & Akta Cepat Terintegrasi".
- Action Card: Floating glass box with primary CTA "Cek Status Pengajuan" and "Akses Petugas Rumah Sakit".
- Bottom Section: 3 glass feature cards with modern line icons (Keamanan Data, Verifikasi Online Dukcapil, Integrasi 29 RS/Puskesmas).
```

### 📄 Modul 2: Cek Status Publik (/tracking)
```text
Design a public tracking screen in Glassmorphism style with a dedicated civic/community background photo.
- Background: High-res background image with a frosted glass backdrop filter.
- Search Card: Prominent centered glass card with dual search options (Tab 1: Berdasarkan NIK Ibu Kandung, Tab 2: Berdasarkan Nomor Registrasi REG-...).
- Search Input: Sleek glass input field with search icon and vibrant Cyan CTA button "Lacak Status".
- Live Timeline Card: Floating glass panel showing progress steps:
  * Step 1: Draf Tersimpan di RS/Puskesmas (Timestamp & Nama Faskes).
  * Step 2: Berkas Dikirim ke Disdukcapil (Status: Menunggu Verifikasi).
  * Step 3: Verifikasi Berkas (Catatan perbaikan jika ada berkas buram/salah).
  * Step 4: Akta Kelahiran Selesai Diterbitkan (Nomor Akta resmi & Tombol Unduh PDF).
- Security Notice: Subtle glass footer note: "Data dilindungi oleh enkripsi Dukcapil dan hanya dapat diakses dengan NIK resmi".
```

### 📄 Modul 3: Petugas Login Screen (/login)
```text
Design a minimalist Adaptive Glassmorphic Login Screen for government and healthcare operators.
- Background: Architectural healthcare/hospital background photo with deep ambient blur.
- Card: Perfectly centered floating glass card with rounded corners (24px), 1px translucent white border, and soft drop shadow.
- Header inside card: Logo emblem, "Sistem Lalapan", subtitle "Silakan masuk dengan akun instansi Anda".
- Role Selector: Frosted glass segmented pill tabs [Faskes / RS] [Dukcapil] [Admin].
- Inputs: Sleek glass input fields with icons (User icon for username, Lock icon for password with show/hide eye).
- Button: Full-width vibrant blue gradient button with hover shine effect "Masuk ke Sistem".
- Footer badge: Small bottom glass pill showing "Koneksi Backend Aktif: 127.0.0.1:5055".
```

### 📄 Modul 4: Faskes & Dukcapil Dashboard (/dashboard)
```text
Design a high-productivity Adaptive Glassmorphism Dashboard for Hospital operators and Dukcapil officers.
- Header: Glass app bar with Faskes selector badge ("RSUD dr. Soedono"), search bar, notification bell, and user profile avatar.
- KPI Metric Cards: 4 floating glass metric tiles with glowing accent borders:
  1. Total Laporan (Blue)
  2. Menunggu Verifikasi (Amber)
  3. Perlu Perbaikan (Coral Red)
  4. Selesai Terbit (Emerald Green)
- Action Toolbar: Quick search input, status filter chips, and primary "+ Buat Pengajuan Baru" glass button.
- Application Table/List: Modern glass data table with columns: No. Registrasi, Nama Bayi, NIK Ibu, Tanggal Lahir, Faskes Pengaju, Status Badge (frosted colored pills), and Quick Actions menu.
```

### 📄 Modul 5: 3-Step Birth Registration Form Wizard (/applications/new)
```text
Design a multi-step Birth Registration Wizard in clean Glassmorphic style.
- Stepper: Floating glass pill bar at the top indicating Step 1 (Bayi), Step 2 (Orang Tua), Step 3 (6 Dokumen Wajib).
- Content Area: Floating frosted glass container with smooth form fields:
  * Section 1: Data Bayi (Nama Lengkap, Jenis Kelamin toggle buttons, Tanggal & Jam Lahir, Berat Badan kg/gram, Panjang Badan cm).
  * Section 2: Data Ibu & Ayah (NIK Ibu, Nama Ibu, NIK Ayah, Nama Ayah, No KK, No HP).
  * Section 3: 6 Document Upload Tiles: 2-column grid of glass dropzones for KTP Ibu, KTP Ayah, KK, Surat Lahir, Buku Nikah, Rekam Medis. Each tile has an upload icon, file format indicator (JPG/PNG/PDF max 5MB), and preview badge once uploaded.
- Floating Footer: Glass bottom bar with "Simpan Draf" (neutral glass) and "Kirim Pengajuan" (vibrant blue glass).
```

### 📄 Modul 6: Document Viewer & Disdukcapil Verification Studio (/verification/:id)
```text
Design a split-screen Verification & Document Inspector Studio in Glassmorphism style.
- Left Panel (40% width): Glass card with applicant summary, child identity, parental info, and audit trail timeline.
- Right Panel (60% width): Interactive document previewer displaying submitted PDF or high-res photo with floating frosted glass toolbar (Zoom +, Zoom -, Rotate 90 deg, Download).
- Checklist Section: Glass checklist card below document viewer:
  * Checklist item for each of the 6 documents with "Valid ✓" or "Revisi ✗".
  * Expandable revision notes box for the officer to input feedback for the hospital.
- Decision Dock: Floating glass bottom dock with 3 actions: "Minta Perbaikan" (Coral Red), "Tolak" (Slate), and "Setujui & Terbitkan Nomor Akta" (Emerald Green with dialog popup).
```

---

## 🖼️ 3. PANDUAN PENYIAPAN BACKGROUND IMAGE KHUSUS

Berdasarkan pilihan Anda, berikut adalah spesifikasi 3 gambar latar belakang khusus yang disiapkan:

| Halaman | Nama File Aset yang Disarankan | Rekomendasi Visual | Dimensi Rekomendasi | Format File |
|---|---|---|---|---|
| **1. Landing Page** | `assets/images/bg_landing.webp` | Foto keluarga bahagia / ibu & bayi baru lahir, pencahayaan alami hangat (*warm golden hour / soft studio*) | 1920 × 1080 (Web) / 1080 × 2400 (Mobile) | WebP / JPG (< 500 KB) |
| **2. Login Petugas** | `assets/images/bg_login.webp` | Arsitektur modern rumah sakit / instansi pemerintahan dengan pencahayaan lembut & kedalaman fokus (*bokeh/depth-of-field*) | 1920 × 1080 (Web) / 1080 × 2400 (Mobile) | WebP / JPG (< 400 KB) |
| **3. Cek Status Publik** | `assets/images/bg_tracker.webp` | Visual komunitas / dokumen sipil / sentuhan kehangatan keluarga cerah & clean | 1920 × 1080 (Web) / 1080 × 2400 (Mobile) | WebP / JPG (< 500 KB) |

### Implementasi Scrim Overlay di Atas Gambar:
Setiap gambar akan dipasangi filter scrim agar teks dan panel kaca memiliki kontras WCAG AAA (selalu tajam dan mudah dibaca):

```dart
// Pola Scrim Overlay Flutter:
Stack(
  children: [
    // 1. Background Image
    Positioned.fill(
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
      ),
    ),
    // 2. Adaptive Scrim Layer
    Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    const Color(0xFF0F172A).withOpacity(0.65),
                    const Color(0xFF0F172A).withOpacity(0.85),
                  ]
                : [
                    Colors.black.withOpacity(0.35),
                    const Color(0xFF1E40AF).withOpacity(0.40),
                    const Color(0xFF0F172A).withOpacity(0.70),
                  ],
          ),
        ),
      ),
    ),
    // 3. Floating Glass UI Content
    SafeArea(child: contentWidget),
  ],
)
```

---

## 💻 4. BLUEPRINT KOMPONEN FLUTTER ADAPTIVE GLASSMORPHISM

Komponen reusable yang siap dipasang di Flutter (`lalapan_mobile`) setelah UI dari Stitch di-generate:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class AdaptiveGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double? lightOpacity;
  final double? darkOpacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;

  const AdaptiveGlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.lightOpacity,
    this.darkOpacity,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20.0);

    // Dynamic glass parameters according to theme
    final baseColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final effectiveOpacity = isDark
        ? (darkOpacity ?? 0.70)
        : (lightOpacity ?? 0.78);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.45);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: baseColor.withOpacity(effectiveOpacity),
              borderRadius: effectiveRadius,
              border: border ??
                  Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(isDark ? 0.30 : 0.08),
                  blurRadius: 32.0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```
