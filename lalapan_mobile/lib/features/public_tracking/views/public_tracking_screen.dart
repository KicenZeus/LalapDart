import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/tracking_model.dart';

class PublicTrackingScreen extends StatefulWidget {
  const PublicTrackingScreen({super.key});

  @override
  State<PublicTrackingScreen> createState() => _PublicTrackingScreenState();
}

class _PublicTrackingScreenState extends State<PublicTrackingScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchSectionKey = GlobalKey();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;
  List<TrackingModel> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final response = await _apiClient.dio.get(
        '/applications/public/track',
        queryParameters: {'q': query},
      );

      final List rawData = response.data['data'] ?? [];
      setState(() {
        _results = rawData.map((e) => TrackingModel.fromJson(e)).toList();
        _isLoading = false;
      });

      // Scroll smoothly to results
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchSectionKey.currentContext != null) {
          Scrollable.ensureVisible(
            _searchSectionKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Data permohonan tidak ditemukan dengan kata kunci "$query". Pastikan nomor registrasi atau NIK benar.';
      });
    }
  }

  void _scrollToSearch() {
    if (_searchSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _searchSectionKey.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Canvas
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF0F172A),
                          Color(0xFF1E293B),
                          Color(0xFF0F172A),
                        ]
                      : const [
                          Color(0xFFF0F7FF),
                          Color(0xFFE0F2FE),
                          Color(0xFFF8FAFC),
                        ],
                ),
              ),
            ),
          ),

          // Main Scrollable Page
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. FLOATING GLASS NAVBAR
                      _buildFloatingNavbar(context, isDark),
                      const SizedBox(height: 24),

                      // 2. HERO SECTION DENGAN GAMBAR VECTOR & TULISAN HOVER
                      _buildHeroSection(isDark),
                      const SizedBox(height: 32),

                      // 3. FITUR UTAMA SISTEM (3 KARTU KACA)
                      _buildFeatureHighlights(isDark),
                      const SizedBox(height: 32),

                      // 4. MODUL PENCARIAN & PELACAKAN DENGAN GLASSMORPHISM
                      _buildTrackingSearchSection(isDark),
                      const SizedBox(height: 24),

                      // 5. PESAN ERROR
                      if (_errorMessage != null) ...[
                        _buildErrorMessage(_errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      // 6. HASIL PELACAKAN
                      if (_results.isNotEmpty) ...[
                        for (final item in _results) ...[
                          _buildTrackingResultCard(item, isDark),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // 7. FOOTER PEMKAB MADIUN
                      _buildFooter(isDark),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating Glass Navigation Bar
  Widget _buildFloatingNavbar(BuildContext context, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      borderRadius: BorderRadius.circular(16.0),
      opacity: isDark ? 0.65 : 0.85,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Branding
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LALAPAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'KABUPATEN MADIUN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.blue.shade300 : const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Action Buttons
          Row(
            children: [
              TextButton.icon(
                onPressed: _scrollToSearch,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Cek Status', style: TextStyle(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.blue.shade300 : const Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Portal Petugas', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Hero Section Menampilkan Teks Hover di Atas, Gambar Vector di Tengah, dan Teks Nilai di Bawah
  Widget _buildHeroSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // -------------------------------------------------------------
        // A. TULISAN HOVER DI ATAS GAMBAR
        // -------------------------------------------------------------
        GlassContainer(
          enableHover: true,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          borderRadius: BorderRadius.circular(24.0),
          opacity: isDark ? 0.70 : 0.85,
          child: Column(
            children: [
              // Badge Kolaborasi Resmi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.12),
                      const Color(0xFF06B6D4).withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SISTEM DIGITAL TERPADU KABUPATEN MADIUN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.blue.shade200 : const Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Headline Utama
              Text(
                'Pengajuan Akta Kelahiran\nFaskes × Dukcapil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Sub-Kabupaten Madiun
              Text(
                'Kab. Madiun',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // -------------------------------------------------------------
        // B. GAMBAR VECTOR (landingpage1.png)
        // -------------------------------------------------------------
        GlassContainer(
          padding: const EdgeInsets.all(12.0),
          borderRadius: BorderRadius.circular(28.0),
          opacity: isDark ? 0.40 : 0.90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              color: Colors.white,
              child: Image.asset(
                'assets/images/landingpage1.png',
                fit: BoxFit.contain,
                height: 380,
                width: double.infinity,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // -------------------------------------------------------------
        // C. TEKS RINGKAS & VALUE PROPOSITION DI BAWAH GAMBAR
        // -------------------------------------------------------------
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          borderRadius: BorderRadius.circular(22.0),
          opacity: isDark ? 0.65 : 0.82,
          child: Column(
            children: [
              Text(
                'Layanan percepatan penerbitan Akta Kelahiran resmi langsung dari fasilitas kesehatan (RSUD & Puskesmas) terverifikasi secara digital oleh Disdukcapil Kabupaten Madiun.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _scrollToSearch,
                    icon: const Icon(Icons.search_rounded, size: 20),
                    label: const Text('Lacak Status Berkas Anda', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.lock_outline_rounded, size: 18),
                    label: const Text('Portal Petugas Faskes / Dukcapil', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.blue.shade300 : const Color(0xFF1E40AF),
                      side: BorderSide(
                        color: isDark ? Colors.blue.shade400.withValues(alpha: 0.4) : const Color(0xFF2563EB),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3 Kartu Keunggulan Sistem (Feature Highlights)
  Widget _buildFeatureHighlights(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 650;
        final cards = [
          _buildFeatureCard(
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFF2563EB),
            title: 'Integrasi 29 Faskes',
            description: 'Pelaporan kelahiran langsung diinput oleh bidan & petugas rumah sakit saat persalinan selesai.',
            isDark: isDark,
          ),
          _buildFeatureCard(
            icon: Icons.security_rounded,
            color: const Color(0xFF06B6D4),
            title: 'Verifikasi Disdukcapil',
            description: '6 berkas persyaratan diperiksa langsung secara digital oleh verifikator Dukcapil.',
            isDark: isDark,
          ),
          _buildFeatureCard(
            icon: Icons.verified_rounded,
            color: const Color(0xFF10B981),
            title: 'Akta Digital Sah',
            description: 'Nomor resmi Akta Kelahiran langsung diterbitkan tanpa antre fisik di kantor dinas.',
            isDark: isDark,
          ),
        ];

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return GlassContainer(
      enableHover: true,
      padding: const EdgeInsets.all(18.0),
      borderRadius: BorderRadius.circular(20.0),
      opacity: isDark ? 0.60 : 0.80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Modul Pencarian & Pelacakan Status Berkas
  Widget _buildTrackingSearchSection(bool isDark) {
    return GlassContainer(
      key: _searchSectionKey,
      padding: const EdgeInsets.all(24.0),
      borderRadius: BorderRadius.circular(24.0),
      opacity: isDark ? 0.70 : 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.track_changes_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portal Pelacakan Status Berkas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Masukkan Nomor Registrasi (REG-...) atau NIK Ibu Kandung untuk memantau status secara langsung.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search Input & Button Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: PGJ-202610-001 atau NIK 16 digit...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Lacak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Banner Pesan Error
  Widget _buildErrorMessage(String message) {
    return GlassContainer(
      padding: const EdgeInsets.all(16.0),
      borderRadius: BorderRadius.circular(16.0),
      baseColor: const Color(0xFFFEF2F2),
      border: Border.all(color: const Color(0xFFFCA5A5)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Hasil Pelacakan Pengajuan
  Widget _buildTrackingResultCard(TrackingModel item, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(22.0),
      borderRadius: BorderRadius.circular(22.0),
      opacity: isDark ? 0.75 : 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Registrasi & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor Registrasi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.registrationNumber,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              StatusBadge(status: item.status),
            ],
          ),
          const Divider(height: 28),

          // Detail Identitas Bayi & Orang Tua
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Bayi',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.babyName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ibu Kandung',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.motherName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fasilitas Kesehatan Pengaju',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.institutionName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade200 : const Color(0xFF334155),
                ),
              ),
            ],
          ),

          // Jika Akta Resmi Telah Terbit
          if (item.aktaKelahiranNumber != null && item.aktaKelahiranNumber!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Akta Kelahiran Resmi Telah Terbit',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                        ),
                        Text(
                          item.aktaKelahiranNumber!,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Jika Perlu Perbaikan (Banner Catatan Dukcapil)
          if (item.publicInstruction != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.publicInstruction!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),
          Text(
            'Linimasa Perkembangan Dokumen',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Stepper Progress Timeline
          for (int i = 0; i < item.timeline.length; i++) ...[
            _buildTimelineTile(
              item.timeline[i],
              isLast: i == item.timeline.length - 1,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineTile(TimelineStepModel step, {required bool isLast, required bool isDark}) {
    Color iconColor;
    IconData iconData;

    switch (step.status) {
      case 'COMPLETED':
        iconColor = const Color(0xFF10B981);
        iconData = Icons.check_circle_rounded;
        break;
      case 'IN_PROGRESS':
        iconColor = const Color(0xFF2563EB);
        iconData = Icons.radio_button_checked_rounded;
        break;
      case 'REVISION_REQUIRED':
        iconColor = const Color(0xFFF59E0B);
        iconData = Icons.error_outline_rounded;
        break;
      default:
        iconColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
        iconData = Icons.radio_button_unchecked_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garis Vertikal & Bulatan
          Column(
            children: [
              Icon(iconData, color: iconColor, size: 20),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.status == 'COMPLETED'
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Teks Status
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: step.status == 'PENDING'
                          ? (isDark ? Colors.grey.shade500 : Colors.grey)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: step.status == 'PENDING'
                          ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
                          : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Footer Resmi Pemkab Madiun
  Widget _buildFooter(bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      borderRadius: BorderRadius.circular(16.0),
      opacity: isDark ? 0.50 : 0.70,
      child: Center(
        child: Text(
          '© 2026 Pemerintah Kabupaten Madiun — Dinas Kependudukan dan Pencatatan Sipil bekerjasama dengan 29 Fasilitas Kesehatan se-Kab. Madiun.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
