import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/status_badge.dart';

class VerificationQueueScreen extends StatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  State<VerificationQueueScreen> createState() => _VerificationQueueScreenState();
}

class _VerificationQueueScreenState extends State<VerificationQueueScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _queueItems = [];
  List<dynamic> _institutions = [];
  String? _selectedInstitutionId;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
    _loadQueue();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    try {
      final res = await _apiClient.dio.get('/institutions');
      if (mounted) {
        setState(() {
          _institutions = res.data['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> params = {};
      if (_selectedInstitutionId != null) params['institutionId'] = _selectedInstitutionId;
      if (_searchCtrl.text.trim().isNotEmpty) params['search'] = _searchCtrl.text.trim();

      final res = await _apiClient.dio.get('/verification/queue', queryParameters: params);
      if (mounted) {
        setState(() {
          _queueItems = res.data['data']?['items'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Dialog Persetujuan Cepat
  Future<void> _showQuickApproveDialog(String applicationId, String regNo) async {
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}";
    final aktaCtrl = TextEditingController(text: '3519-LT-$dateStr-0001');
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Setujui & Terbitkan Akta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor Registrasi: $regNo', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 14),
              TextField(
                controller: aktaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomor Akta Kelahiran Resmi *',
                  hintText: 'Contoh: 3519-LT-22102026-0001',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => navigator.pop(), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (aktaCtrl.text.trim().isEmpty) return;
                try {
                  await _apiClient.dio.post(
                    '/verification/$applicationId/approve',
                    data: {'aktaKelahiranNumber': aktaCtrl.text.trim()},
                  );
                  navigator.pop();
                  await _loadQueue();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Akta Kelahiran resmi berhasil diterbitkan!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal menyetujui: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Terbitkan Akta'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog Checklist Revisi Cepat
  Future<void> _showQuickRevisionDialog(String applicationId, String regNo) async {
    final noteCtrl = TextEditingController();
    final selectedDocs = <String>{};
    final selectedFields = <String>{};
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final fields = [
      {'key': 'baby_name', 'label': 'Nama Lengkap Bayi'},
      {'key': 'baby_birth_date', 'label': 'Tanggal Lahir Bayi'},
      {'key': 'baby_birth_place', 'label': 'Tempat Lahir (RS/Puskesmas)'},
      {'key': 'medical_record_no', 'label': 'Nomor Rekam Medis RS'},
      {'key': 'mother_name', 'label': 'Nama Lengkap Ibu Kandung'},
    ];

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Minta Perbaikan: $regNo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tandai Dokumen Bermasalah / Buram:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 6),
                      for (final doc in DocumentType.values)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(doc.label, style: const TextStyle(fontSize: 12)),
                          value: selectedDocs.contains(doc.code),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedDocs.add(doc.code);
                              } else {
                                selectedDocs.remove(doc.code);
                              }
                            });
                          },
                        ),
                      const Divider(height: 16),
                      const Text('Tandai Isian Teks Salah:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 6),
                      for (final f in fields)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(f['label']!, style: const TextStyle(fontSize: 12)),
                          value: selectedFields.contains(f['key']),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedFields.add(f['key']!);
                              } else {
                                selectedFields.remove(f['key']);
                              }
                            });
                          },
                        ),
                      const Divider(height: 16),
                      TextField(
                        controller: noteCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Resmi Perbaikan *',
                          hintText: 'Tuliskan detail perbaikan untuk operator Faskes...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => navigator.pop(), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (noteCtrl.text.trim().isEmpty) return;
                    try {
                      await _apiClient.dio.post(
                        '/verification/$applicationId/request-revision',
                        data: {
                          'revisionNote': noteCtrl.text.trim(),
                          'documentChecklist': selectedDocs.toList(),
                          'fieldChecklist': selectedFields.toList(),
                        },
                      );
                      navigator.pop();
                      await _loadQueue();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Permintaan perbaikan berhasil dikirim ke Faskes.')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Gagal mengirim revisi: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Kirim Revisi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Antrean Verifikasi Dukcapil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari no registrasi / nama bayi...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (_) => _loadQueue(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: _loadQueue,
                        child: const Text('Cari'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _selectedInstitutionId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      labelText: 'Filter Asal Faskes',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Faskes (Lintas 29 Faskes)')),
                      for (final inst in _institutions)
                        DropdownMenuItem(
                          value: inst['id']?.toString(),
                          child: Text(inst['name'] ?? '', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedInstitutionId = val);
                      _loadQueue();
                    },
                  ),
                ],
              ),
            ),

            // Queue List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _queueItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('Tidak ada antrean permohonan masuk saat ini.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadQueue,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _queueItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _queueItems[index];
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => context.push('/verification/${item['id']}'),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item['registration_number'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                                            ),
                                            const StatusBadge(status: 'MENUNGGU_VERIFIKASI'),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Bayi: ${item['baby_name']} (${item['baby_gender'] == 'LAKI_LAKI' ? 'Laki-laki' : 'Perempuan'})',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        Text(
                                          'Ibu Kandung: ${item['mother_name']}',
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                        Text(
                                          'Asal Faskes: ${item['institution_name']}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const Divider(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.open_in_new, size: 16),
                                              label: const Text('Detail & Berkas'),
                                              onPressed: () => context.push('/verification/${item['id']}'),
                                            ),
                                            const SizedBox(width: 4),
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.edit_note, size: 16, color: Colors.amber),
                                              label: const Text('Revisi', style: TextStyle(color: Colors.amber)),
                                              onPressed: () => _showQuickRevisionDialog(item['id'], item['registration_number']),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.check, size: 16),
                                              label: const Text('Setujui'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _showQuickApproveDialog(item['id'], item['registration_number']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
