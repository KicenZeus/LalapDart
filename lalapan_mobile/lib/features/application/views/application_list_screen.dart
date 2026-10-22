import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/application_provider.dart';

class ApplicationListScreen extends ConsumerStatefulWidget {
  const ApplicationListScreen({super.key});

  @override
  ConsumerState<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends ConsumerState<ApplicationListScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(applicationListProvider.notifier).loadApplications();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    ref.read(applicationListProvider.notifier).loadApplications(
          status: _selectedStatus,
          search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(applicationListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Daftar Pengajuan Kelahiran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Buat Pengajuan Baru',
            onPressed: () => context.go('/applications/new'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Cari nomor registrasi / nama...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _applyFilter(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    value: _selectedStatus,
                    hint: const Text('Semua Status', style: TextStyle(fontSize: 12)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Status')),
                      DropdownMenuItem(value: 'DRAFT', child: Text('Draf')),
                      DropdownMenuItem(value: 'MENUNGGU_VERIFIKASI', child: Text('Menunggu Verif')),
                      DropdownMenuItem(value: 'PERLU_PERBAIKAN', child: Text('Perlu Perbaikan')),
                      DropdownMenuItem(value: 'DISETUJUI', child: Text('Disetujui')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStatus = val);
                      _applyFilter();
                    },
                  ),
                ],
              ),
            ),

            // List Pengajuan
            Expanded(
              child: listState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : listState.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('Belum ada pengajuan kelahiran.', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Buat Pengajuan Sekarang'),
                                onPressed: () => context.go('/applications/new'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _applyFilter(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: listState.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = listState.items[index];
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.registrationNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                      ),
                                      StatusBadge(status: item.status),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Bayi: ${item.baby?.fullName ?? "-"}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text('Ibu: ${item.mother?.fullName ?? "-"}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        if (item.status == 'PERLU_PERBAIKAN' && item.lastRevisionNote != null)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('Catatan Revisi: ${item.lastRevisionNote}',
                                                style: TextStyle(color: Colors.amber.shade900, fontSize: 11)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    if (item.status == 'DRAFT' || item.status == 'PERLU_PERBAIKAN') {
                                      context.go('/applications/new');
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
