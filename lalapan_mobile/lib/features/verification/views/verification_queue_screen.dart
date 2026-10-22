import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/verification/queue');
      setState(() {
        _queueItems = res.data['data']?['items'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// Dialog Minta Perbaikan (Checklist Revisi)
  Future<void> _showRevisionDialog(String applicationId, String regNo) async {
    final noteCtrl = TextEditingController();
    final selectedDocs = <String>{};
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Minta Perbaikan: $regNo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Centang dokumen yang bermasalah / buram:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (final doc in DocumentType.values)
                      CheckboxListTile(
                        dense: true,
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
                    const SizedBox(height: 12),
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
              actions: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: const Text('Batal'),
                ),
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
                          'fieldChecklist': [],
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

  /// Dialog Persetujuan & Terbitkan Nomor Akta
  Future<void> _showApproveDialog(String applicationId, String regNo) async {
    final aktaCtrl = TextEditingController(text: '3519-LT-${DateTime.now().day}${DateTime.now().month}${DateTime.now().year}-0001');
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
              const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Antrean Verifikasi Dukcapil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
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
                      padding: const EdgeInsets.all(16),
                      itemCount: _queueItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _queueItems[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                  'Ibu: ${item['mother_name']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                                Text(
                                  'Faskes: ${item['institution_name']}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.edit_note, size: 16, color: Colors.amber),
                                      label: const Text('Minta Perbaikan', style: TextStyle(color: Colors.amber)),
                                      onPressed: () => _showRevisionDialog(item['id'], item['registration_number']),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Setujui Akta'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _showApproveDialog(item['id'], item['registration_number']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
