import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'total': 0,
    'draft': 0,
    'menungguVerifikasi': 0,
    'perluPerbaikan': 0,
    'disetujui': 0,
    'ditolak': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/dashboard/stats');
      setState(() {
        _stats = res.data['data'] ?? _stats;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Dashboard Lalapan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final router = GoRouter.of(context);
              await ref.read(authProvider.notifier).logout();
              router.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kartu Sambutan Petugas
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.blue.shade800,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            user?.isOperatorDukcapil == true ? Icons.verified_user : Icons.medical_services,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Petugas',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.institutionName ?? 'Disdukcapil Kabupaten Madiun',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user?.role ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Ringkasan Statistik
                const Text(
                  'Ringkasan Status Permohonan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildMetricCard('Total Pengajuan', _stats['total'].toString(), Icons.folder_shared, Colors.blue),
                      _buildMetricCard('Draf Awal', _stats['draft'].toString(), Icons.edit_note, Colors.grey),
                      _buildMetricCard('Menunggu Verifikasi', _stats['menungguVerifikasi'].toString(), Icons.hourglass_top, Colors.indigo),
                      _buildMetricCard('Perlu Perbaikan', _stats['perluPerbaikan'].toString(), Icons.warning_amber_rounded, Colors.amber.shade800),
                      _buildMetricCard('Disetujui', _stats['disetujui'].toString(), Icons.check_circle_outline, Colors.green),
                    ],
                  ),

                const SizedBox(height: 28),

                // Menu Cepat Sesuai Peran
                const Text('Menu Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (user?.isOperatorRs == true || user?.isAdmin == true) ...[
                  _buildMenuTile(
                    title: 'Buat Pengajuan Kelahiran Baru',
                    subtitle: 'Isi formulir data bayi, ibu, dan unggah 6 berkas persyaratan',
                    icon: Icons.add_circle,
                    color: Colors.blue.shade700,
                    onTap: () => context.go('/applications/new'),
                  ),
                  const SizedBox(height: 10),
                  _buildMenuTile(
                    title: 'Daftar Pengajuan Faskes',
                    subtitle: 'Lihat seluruh draf, pengajuan terkirim, dan status revisi',
                    icon: Icons.list_alt,
                    color: Colors.teal,
                    onTap: () => context.go('/applications'),
                  ),
                  const SizedBox(height: 10),
                ],

                if (user?.isOperatorDukcapil == true || user?.isAdmin == true) ...[
                  _buildMenuTile(
                    title: 'Antrean Verifikasi Dukcapil',
                    subtitle: 'Validasi kelengkapan berkas, checklist revisi, dan terbitkan akta',
                    icon: Icons.rule,
                    color: Colors.indigo.shade700,
                    onTap: () => context.go('/verification'),
                  ),
                  const SizedBox(height: 10),
                ],

                _buildMenuTile(
                  title: 'Portal Pelacakan Publik',
                  subtitle: 'Simulasikan pencarian berkas seperti di sisi warga',
                  icon: Icons.search,
                  color: Colors.purple,
                  onTap: () => context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
