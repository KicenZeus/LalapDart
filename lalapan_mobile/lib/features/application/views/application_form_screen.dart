import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/application_model.dart';
import '../providers/application_provider.dart';

class ApplicationFormScreen extends ConsumerStatefulWidget {
  final String? editApplicationId;

  const ApplicationFormScreen({super.key, this.editApplicationId});

  @override
  ConsumerState<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  int _currentStep = 0;
  final ApiClient _apiClient = ApiClient();

  // Step 1 Controllers
  final _formKeyStep1 = GlobalKey<FormState>();
  final _babyNameCtrl = TextEditingController();
  String _gender = 'LAKI_LAKI';
  final int _birthOrder = 1;
  final _birthWeightCtrl = TextEditingController(text: '3200');
  final _birthLengthCtrl = TextEditingController(text: '49.0');
  final _birthPlaceCtrl = TextEditingController(text: 'Kabupaten Madiun');
  final _birthDateCtrl = TextEditingController(text: '2026-10-22');
  final _birthTimeCtrl = TextEditingController(text: '07:30');
  final String _condition = 'SEHAT';
  final _medicalRecordCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();

  // State Draf yang tersimpan
  String? _savedApplicationId;
  String? _savedRegistrationNumber;
  bool _isSavingDraft = false;

  // Step 2 Uploaded Documents Map
  final Map<String, ApplicationDocumentModel> _uploadedDocs = {};
  bool _isUploadingDoc = false;
  String? _uploadingDocType;

  @override
  void dispose() {
    _babyNameCtrl.dispose();
    _birthWeightCtrl.dispose();
    _birthLengthCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _birthDateCtrl.dispose();
    _birthTimeCtrl.dispose();
    _medicalRecordCtrl.dispose();
    _motherNameCtrl.dispose();
    super.dispose();
  }

  /// Simpan Draf ke Backend (Langkah 1)
  Future<bool> _saveDraft() async {
    if (!_formKeyStep1.currentState!.validate()) return false;

    setState(() => _isSavingDraft = true);

    try {
      final baby = BabyModel(
        fullName: _babyNameCtrl.text.trim(),
        gender: _gender,
        birthOrder: _birthOrder,
        birthWeightGram: int.tryParse(_birthWeightCtrl.text),
        birthLengthCm: double.tryParse(_birthLengthCtrl.text),
        birthPlace: _birthPlaceCtrl.text.trim(),
        birthDate: _birthDateCtrl.text.trim(),
        birthTime: _birthTimeCtrl.text.trim(),
        condition: _condition,
        medicalRecordNo: _medicalRecordCtrl.text.trim().isEmpty ? null : _medicalRecordCtrl.text.trim(),
      );

      final mother = MotherModel(fullName: _motherNameCtrl.text.trim());

      final app = await ref.read(applicationListProvider.notifier).createDraft(baby: baby, mother: mother);

      if (app != null) {
        setState(() {
          _savedApplicationId = app.id;
          _savedRegistrationNumber = app.registrationNumber;
          _isSavingDraft = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Draf berhasil disimpan: ${app.registrationNumber}')),
          );
        }
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan draf: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSavingDraft = false);
    }
    return false;
  }

  /// Pilih Berkas & Unggah Dokumen (Langkah 2)
  Future<void> _pickAndUploadDocument(DocumentType docType) async {
    if (_savedApplicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap simpan formulir data bayi & ibu terlebih dahulu!')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _isUploadingDoc = true;
      _uploadingDocType = docType.code;
    });

    try {
      final formData = FormData.fromMap({
        'applicationId': _savedApplicationId,
        'documentType': docType.code,
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });

      final response = await _apiClient.dio.post('/documents/upload', data: formData);
      final docData = ApplicationDocumentModel.fromJson(response.data['data']);

      setState(() {
        _uploadedDocs[docType.code] = docData;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil mengunggah ${docType.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah berkas: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isUploadingDoc = false;
        _uploadingDocType = null;
      });
    }
  }

  /// Submit Final Pengajuan ke Dukcapil (Langkah 3)
  Future<void> _submitFinalApplication() async {
    if (_savedApplicationId == null) return;

    final allDocsUploaded = DocumentType.values.every((d) => _uploadedDocs.containsKey(d.code));
    if (!allDocsUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seluruh 6 dokumen persyaratan wajib diunggah sebelum pengajuan dikirim!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _apiClient.dio.post('/applications/$_savedApplicationId/submit');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan resmi berhasil dikirim ke antrean verifikasi Dukcapil!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pengajuan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pengajuan Kelahiran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (step) {
            if (step > _currentStep && _savedApplicationId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Harap simpan data bayi & ibu terlebih dahulu.')),
              );
              return;
            }
            setState(() => _currentStep = step);
          },
          onStepContinue: () async {
            if (_currentStep == 0) {
              final ok = await _saveDraft();
              if (ok) setState(() => _currentStep = 1);
            } else if (_currentStep == 1) {
              setState(() => _currentStep = 2);
            } else if (_currentStep == 2) {
              await _submitFinalApplication();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              context.pop();
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isSavingDraft ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSavingDraft
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_currentStep == 2 ? 'Kirim ke Dukcapil' : 'Simpan & Lanjut'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Kembali'),
                    ),
                ],
              ),
            );
          },
          steps: [
            // Langkah 1: Data Bayi & Ibu
            Step(
              title: const Text('Data Bayi & Ibu'),
              isActive: _currentStep >= 0,
              state: _savedApplicationId != null ? StepState.complete : StepState.indexed,
              content: _buildStep1Form(),
            ),
            // Langkah 2: 6 Dokumen Persyaratan
            Step(
              title: const Text('6 Berkas Wajib'),
              isActive: _currentStep >= 1,
              state: _uploadedDocs.length == 6 ? StepState.complete : StepState.indexed,
              content: _buildStep2Uploads(),
            ),
            // Langkah 3: Review & Submit
            Step(
              title: const Text('Review & Kirim'),
              isActive: _currentStep >= 2,
              content: _buildStep3Review(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Form() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Identitas Bayi Baru Lahir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _babyNameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Lengkap Bayi *', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Nama bayi wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Jenis Kelamin *', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'LAKI_LAKI', child: Text('Laki-laki')),
              DropdownMenuItem(value: 'PEREMPUAN', child: Text('Perempuan')),
            ],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _birthDateCtrl,
                  decoration: const InputDecoration(labelText: 'Tanggal Lahir (YYYY-MM-DD) *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _birthTimeCtrl,
                  decoration: const InputDecoration(labelText: 'Jam Lahir (HH:MM) *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthPlaceCtrl,
            decoration: const InputDecoration(labelText: 'Tempat Lahir (RS / Puskesmas) *', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Tempat lahir wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _birthWeightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Berat Lahir (Gram)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _birthLengthCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Panjang Lahir (Cm)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _medicalRecordCtrl,
            decoration: const InputDecoration(labelText: 'Nomor Rekam Medis RS/Puskesmas', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text('Identitas Orang Tua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motherNameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Lengkap Ibu Kandung *', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Nama ibu kandung wajib diisi' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Uploads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_savedRegistrationNumber != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Nomor Registrasi Draf: $_savedRegistrationNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        const Text(
          'Unggah 6 Berkas Dokumen Persyaratan Wajib:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        for (final docType in DocumentType.values) ...[
          _buildDocUploadTile(docType),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDocUploadTile(DocumentType docType) {
    final isUploaded = _uploadedDocs.containsKey(docType.code);
    final isCurrentUploading = _isUploadingDoc && _uploadingDocType == docType.code;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          isUploaded ? Icons.check_circle : Icons.upload_file,
          color: isUploaded ? Colors.green : Colors.grey,
        ),
        title: Text(docType.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: isUploaded
            ? Text('Telah terunggah: ${_uploadedDocs[docType.code]?.originalFileName ?? "Berkas lampiran"}',
                style: const TextStyle(fontSize: 11, color: Colors.green))
            : const Text('Belum diunggah (Wajib)', style: TextStyle(fontSize: 11, color: Colors.red)),
        trailing: isCurrentUploading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton.icon(
                onPressed: () => _pickAndUploadDocument(docType),
                icon: Icon(isUploaded ? Icons.edit : Icons.upload, size: 16),
                label: Text(isUploaded ? 'Ganti' : 'Unggah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploaded ? Colors.grey.shade200 : Colors.blue.shade600,
                  foregroundColor: isUploaded ? Colors.black87 : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
      ),
    );
  }

  Widget _buildStep3Review() {
    final totalUploaded = _uploadedDocs.length;
    final isComplete = totalUploaded == 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ringkasan Permohonan Kelahiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Nomor Registrasi', _savedRegistrationNumber ?? '-'),
                _buildReviewRow('Nama Bayi', _babyNameCtrl.text),
                _buildReviewRow('Jenis Kelamin', _gender == 'LAKI_LAKI' ? 'Laki-laki' : 'Perempuan'),
                _buildReviewRow('Tanggal & Jam Lahir', '${_birthDateCtrl.text}, ${_birthTimeCtrl.text}'),
                _buildReviewRow('Tempat Lahir', _birthPlaceCtrl.text),
                _buildReviewRow('Ibu Kandung', _motherNameCtrl.text),
                const Divider(),
                _buildReviewRow('Kelengkapan Dokumen', '$totalUploaded dari 6 berkas terunggah'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isComplete ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isComplete ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(isComplete ? Icons.verified : Icons.warning_amber_rounded,
                  color: isComplete ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isComplete
                    ? 'Seluruh 6 berkas persyaratan lengkap. Anda dapat menekan tombol "Kirim ke Dukcapil".'
                    : 'Peringatan: Dokumen belum lengkap. Harap kembali ke langkah 2 untuk mengunggah sisa berkas.',
                  style: TextStyle(color: isComplete ? Colors.green.shade900 : Colors.red.shade900, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
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
