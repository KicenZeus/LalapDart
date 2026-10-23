import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/status_badge.dart';
import '../../application/models/application_model.dart';

class VerificationDetailScreen extends StatefulWidget {
  final String applicationId;

  const VerificationDetailScreen({super.key, required this.applicationId});

  @override
  State<VerificationDetailScreen> createState() => _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  ApplicationModel? _application;
  BabyModel? _baby;
  MotherModel? _mother;
  List<ApplicationDocumentModel> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/applications/${widget.applicationId}');
      final data = res.data['data'];
      setState(() {
        _application = ApplicationModel.fromJson(data['application']);
        _baby = data['baby'] != null ? BabyModel.fromJson(data['baby']) : null;
        _mother = data['mother'] != null ? MotherModel.fromJson(data['mother']) : null;
        _documents = (data['documents'] as List? ?? [])
            .map((d) => ApplicationDocumentModel.fromJson(d))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail permohonan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Dialog Checklist Minta Perbaikan (Field Teks & Dokumen Lampiran)
  Future<void> _showRevisionDialog() async {
    if (_application == null) return;
    final noteCtrl = TextEditingController();
    final selectedDocs = <String>{};
    final selectedFields = <String>{};
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final verifiableFields = [
      {'key': 'baby_name', 'label': 'Nama Lengkap Bayi'},
      {'key': 'baby_gender', 'label': 'Jenis Kelamin'},
      {'key': 'baby_birth_date', 'label': 'Tanggal Lahir Bayi'},
      {'key': 'baby_birth_time', 'label': 'Jam Kelahiran'},
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
              title: Text(
                'Checklist Revisi: ${_application!.registrationNumber}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Tandai Berkas Dokumen yang Bermasalah / Buram:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
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
                      const Divider(height: 20),
                      const Text(
                        '2. Tandai Isian Teks yang Tidak Sesuai Berkas:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(height: 6),
                      for (final field in verifiableFields)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(field['label']!, style: const TextStyle(fontSize: 12)),
                          value: selectedFields.contains(field['key']),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedFields.add(field['key']!);
                              } else {
                                selectedFields.remove(field['key']);
                              }
                            });
                          },
                        ),
                      const Divider(height: 20),
                      TextField(
                        controller: noteCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Resmi Perbaikan untuk Faskes *',
                          hintText: 'Tuliskan deskripsi lengkap perbaikan yang harus dipenuhi...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
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
                    if (noteCtrl.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Catatan resmi perbaikan wajib diisi!'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    try {
                      await _apiClient.dio.post(
                        '/verification/${widget.applicationId}/request-revision',
                        data: {
                          'revisionNote': noteCtrl.text.trim(),
                          'documentChecklist': selectedDocs.toList(),
                          'fieldChecklist': selectedFields.toList(),
                        },
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Permintaan perbaikan berhasil dikirim ke Faskes.'), backgroundColor: Colors.amber),
                      );
                      await _loadDetail();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Gagal mengirim revisi: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Kirim Revisi ke Faskes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Dialog Persetujuan (Approve) & Input Nomor Akta
  Future<void> _showApproveDialog() async {
    if (_application == null) return;
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}";
    final aktaCtrl = TextEditingController(text: '3519-LT-$dateStr-0001');
    final noteCtrl = TextEditingController(text: 'Dokumen lengkap dan terverifikasi sah.');
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Persetujuan Akta Kelahiran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor Registrasi: ${_application!.registrationNumber}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 14),
              TextField(
                controller: aktaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomor Akta Kelahiran Resmi *',
                  hintText: 'Contoh: 3519-LT-22102026-0001',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Persetujuan (Opsional)',
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
                    '/verification/${widget.applicationId}/approve',
                    data: {
                      'aktaKelahiranNumber': aktaCtrl.text.trim(),
                      'notes': noteCtrl.text.trim(),
                    },
                  );
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Akta Kelahiran resmi berhasil disetujui & diterbitkan!'), backgroundColor: Colors.green),
                  );
                  await _loadDetail();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal menyetujui: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Setujui & Terbitkan Akta'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog Penolakan Definitif (Reject)
  Future<void> _showRejectDialog() async {
    if (_application == null) return;
    final rejectCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Tolak Permohonan Akta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor Registrasi: ${_application!.registrationNumber}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text(
                'Perhatian: Penolakan bersifat definitif. Masukkan alasan resmi penolakan (misal: data fiktif / tidak sah):',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rejectCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan Resmi Penolakan *',
                  hintText: 'Tuliskan alasan definitif penolakan...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => navigator.pop(), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                if (rejectCtrl.text.trim().isEmpty) return;
                try {
                  await _apiClient.dio.post(
                    '/verification/${widget.applicationId}/reject',
                    data: {'rejectNote': rejectCtrl.text.trim()},
                  );
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Permohonan telah ditolak secara resmi.'), backgroundColor: Colors.red),
                  );
                  await _loadDetail();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal menolak: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Tolak Permohonan'),
            ),
          ],
        );
      },
    );
  }

  void _openViewer(ApplicationDocumentModel doc, String label) {
    context.push(
      '/viewer',
      extra: {
        'title': label,
        'fileUrl': doc.fileUrl,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memuat Verifikasi...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permohonan Tidak Ditemukan')),
        body: const Center(child: Text('Data tidak ditemukan.')),
      );
    }

    final isPending = _application!.status == 'MENUNGGU_VERIFIKASI';
    final docsMap = {for (var d in _documents) d.documentType: d};

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Verifikasi: ${_application!.registrationNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_application!.registrationNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                              Text('Faskes: ${_application!.institutionName ?? "-"}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                          StatusBadge(status: _application!.status),
                        ],
                      ),
                      if (_application!.aktaKelahiranNumber != null) ...[
                        const Divider(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('Nomor Akta Resmi: ${_application!.aktaKelahiranNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detail Identitas Bayi & Ibu
              const Text('1. Data Identitas Kelahiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow('Nama Lengkap Bayi', _baby?.fullName ?? '-'),
                      _buildInfoRow('Jenis Kelamin', _baby?.gender == 'LAKI_LAKI' ? 'Laki-laki' : 'Perempuan'),
                      _buildInfoRow('Tanggal Lahir', _baby?.birthDate ?? '-'),
                      _buildInfoRow('Jam Lahir', _baby?.birthTime ?? '-'),
                      _buildInfoRow('Tempat Lahir', _baby?.birthPlace ?? '-'),
                      _buildInfoRow('Berat / Panjang', '${_baby?.birthWeightGram ?? "-"} Gram / ${_baby?.birthLengthCm ?? "-"} Cm'),
                      _buildInfoRow('Kondisi Lahir', _baby?.condition ?? 'SEHAT'),
                      _buildInfoRow('Nomor Rekam Medis', _baby?.medicalRecordNo ?? '-'),
                      const Divider(),
                      _buildInfoRow('Nama Lengkap Ibu', _mother?.fullName ?? '-'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Berkas Lampiran Dokumen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('2. Berkas Lampiran Dokumen Persyaratan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${_documents.length} / 6 Berkas', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              for (final docType in DocumentType.values) ...[
                _buildDocItem(docType, docsMap[docType.code]),
                const SizedBox(height: 6),
              ],

              const SizedBox(height: 24),

              // Tombol Tindakan Keputusan Verifikator
              if (isPending) ...[
                const Text('Tindakan Keputusan Verifikasi Disdukcapil:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Tolak Permohonan', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: _showRejectDialog,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note, color: Colors.amber),
                        label: const Text('Minta Perbaikan', style: TextStyle(color: Colors.amber)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.amber),
                        ),
                        onPressed: _showRevisionDialog,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Setujui & Terbitkan No. Akta Kelahiran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _showApproveDialog,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocItem(DocumentType docType, ApplicationDocumentModel? doc) {
    final isUploaded = doc != null;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          isUploaded ? Icons.file_present : Icons.cancel,
          color: isUploaded ? Colors.indigo : Colors.grey,
        ),
        title: Text(docType.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(
          isUploaded ? 'File: ${doc.originalFileName ?? doc.fileName}' : 'Belum diunggah',
          style: TextStyle(fontSize: 11, color: isUploaded ? Colors.green.shade700 : Colors.red),
        ),
        trailing: isUploaded
            ? ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Buka'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade50,
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _openViewer(doc, docType.label),
              )
            : null,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
