import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingInitial = false;
  String? _applicationStatus;
  String? _lastRevisionNote;
  List<String> _flaggedFields = [];
  List<String> _flaggedDocs = [];

  // Step 1 Controllers
  final _formKeyStep1 = GlobalKey<FormState>();
  final _babyNameCtrl = TextEditingController();
  String _gender = 'LAKI_LAKI';
  int _birthOrder = 1;
  final _birthWeightCtrl = TextEditingController(text: '3200');
  final _birthLengthCtrl = TextEditingController(text: '49.0');
  final _birthPlaceCtrl = TextEditingController(text: 'RSUD Caruban Kabupaten Madiun');
  final _birthDateCtrl = TextEditingController(text: '2026-10-22');
  final _birthTimeCtrl = TextEditingController(text: '07:30');
  String _condition = 'SEHAT';
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
  void initState() {
    super.initState();
    if (widget.editApplicationId != null) {
      _loadApplicationDetail(widget.editApplicationId!);
    }
  }

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

  /// Memuat Data Permohonan jika dalam mode edit / revisi
  Future<void> _loadApplicationDetail(String appId) async {
    setState(() => _isLoadingInitial = true);
    try {
      final res = await _apiClient.dio.get('/applications/$appId');
      final data = res.data['data'];
      final app = data['application'];
      final baby = data['baby'];
      final mother = data['mother'];
      final docs = data['documents'] as List? ?? [];

      _savedApplicationId = app['id'];
      _savedRegistrationNumber = app['registration_number'] ?? app['registrationNumber'] ?? app['pgj_number'];
      _applicationStatus = app['status'];
      _lastRevisionNote = app['last_revision_note'] ?? app['lastRevisionNote'];

      if (baby != null) {
        _babyNameCtrl.text = baby['full_name'] ?? baby['fullName'] ?? '';
        _gender = baby['gender'] ?? 'LAKI_LAKI';
        _birthOrder = baby['birth_order'] ?? baby['birthOrder'] ?? 1;
        _birthWeightCtrl.text = (baby['birth_weight_gram'] ?? baby['birthWeightGram'] ?? '').toString();
        _birthLengthCtrl.text = (baby['birth_length_cm'] ?? baby['birthLengthCm'] ?? '').toString();
        _birthPlaceCtrl.text = baby['birth_place'] ?? baby['birthPlace'] ?? '';
        _birthDateCtrl.text = (baby['birth_date'] ?? baby['birthDate'] ?? '').toString().split('T')[0];
        _birthTimeCtrl.text = baby['birth_time'] ?? baby['birthTime'] ?? '';
        _condition = baby['condition'] ?? 'SEHAT';
        _medicalRecordCtrl.text = baby['medical_record_no'] ?? baby['medicalRecordNo'] ?? '';
      }

      if (mother != null) {
        _motherNameCtrl.text = mother['full_name'] ?? mother['fullName'] ?? '';
      }

      // Populate Dokumen yang sudah ada
      _uploadedDocs.clear();
      for (final d in docs) {
        final docModel = ApplicationDocumentModel.fromJson(d);
        _uploadedDocs[docModel.documentType] = docModel;
      }

      // Ekstrak checklist revisi dari notes
      final notes = app['notes'];
      if (notes is Map) {
        final rev = notes['revision'];
        if (rev is Map) {
          _flaggedFields = List<String>.from(rev['fieldChecklist'] ?? []);
          _flaggedDocs = List<String>.from(rev['documentChecklist'] ?? []);
          if (rev['note'] != null && (_lastRevisionNote == null || _lastRevisionNote!.isEmpty)) {
            _lastRevisionNote = rev['note'];
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail permohonan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  bool _isFieldFlagged(String fieldKey) {
    if (_applicationStatus != 'PERLU_PERBAIKAN') return false;
    return _flaggedFields.contains(fieldKey);
  }

  bool _isDocFlagged(String docTypeCode) {
    if (_applicationStatus != 'PERLU_PERBAIKAN') return false;
    return _flaggedDocs.contains(docTypeCode);
  }

  /// Date Picker Dialog
  Future<void> _selectBirthDate() async {
    DateTime initial = DateTime.tryParse(_birthDateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Kelahiran Bayi',
    );
    if (picked != null) {
      setState(() {
        _birthDateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  /// Time Picker Dialog
  Future<void> _selectBirthTime() async {
    TimeOfDay initial = const TimeOfDay(hour: 7, minute: 30);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Pilih Jam Kelahiran Bayi',
    );
    if (picked != null) {
      setState(() {
        _birthTimeCtrl.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  /// Simpan atau Perbarui Draf ke Backend (Langkah 1)
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

      if (_savedApplicationId != null) {
        // Mode Update Pengajuan Eksisting
        await _apiClient.dio.put(
          '/applications/$_savedApplicationId',
          data: {
            'baby': baby.toJson(),
            'mother': mother.toJson(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Perubahan data draf berhasil diperbarui ($_savedRegistrationNumber)'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        // Mode Buat Baru
        final app = await ref.read(applicationListProvider.notifier).createDraft(baby: baby, mother: mother);

        if (app != null) {
          setState(() {
            _savedApplicationId = app.id;
            _savedRegistrationNumber = app.registrationNumber;
            _applicationStatus = app.status;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Draf berhasil disimpan: ${app.registrationNumber}'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return true;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan draf: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingDraft = false);
      }
    }
    return false;
  }

  /// Dialog Pilihan Sumber Berkas: Kamera vs Galeri vs File Picker
  void _showDocumentSourcePicker(DocumentType docType) {
    if (_savedApplicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap simpan formulir data bayi & ibu terlebih dahulu!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.file_upload, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pilih Sumber: ${docType.label}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.camera_alt),
                  ),
                  title: const Text('Kamera Langsung (Native Camera)'),
                  subtitle: const Text('Ambil foto fisik dokumen menggunakan kamera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromCamera(docType);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.photo_library),
                  ),
                  title: const Text('Galeri Foto Perangkat'),
                  subtitle: const Text('Pilih foto berkas yang sudah tersimpan di galeri'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery(docType);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.folder_open),
                  ),
                  title: const Text('Dokumen / PDF File Picker'),
                  subtitle: const Text('Pilih berkas PDF atau dokumen dari penyimpanan'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromFilePicker(docType);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Ambil Foto Kamera
  Future<void> _pickFromCamera(DocumentType docType) async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _uploadDocumentBytes(docType, bytes, photo.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Akses kamera tidak dapat dibuka: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Ambil Gambar Galeri
  Future<void> _pickFromGallery(DocumentType docType) async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _uploadDocumentBytes(docType, bytes, photo.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Akses galeri tidak dapat dibuka: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Ambil File Picker (PDF / Dokumen)
  Future<void> _pickFromFilePicker(DocumentType docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _uploadDocumentBytes(docType, file.bytes!, file.name);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Unggah Bytes Dokumen ke Server
  Future<void> _uploadDocumentBytes(DocumentType docType, List<int> bytes, String filename) async {
    if (_savedApplicationId == null) return;

    setState(() {
      _isUploadingDoc = true;
      _uploadingDocType = docType.code;
    });

    try {
      final formData = FormData.fromMap({
        'applicationId': _savedApplicationId,
        'documentType': docType.code,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _apiClient.dio.post('/documents/upload', data: formData);
      final docData = ApplicationDocumentModel.fromJson(response.data['data']);

      setState(() {
        _uploadedDocs[docType.code] = docData;
        // Jika dokumen ini tadinya berstatus revisi merah, hapus flag revisinya
        _flaggedDocs.remove(docType.code);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengunggah ${docType.label}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah berkas: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingDoc = false;
          _uploadingDocType = null;
        });
      }
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

    final isResubmit = _applicationStatus == 'PERLU_PERBAIKAN';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isResubmit ? 'Kirim Ulang Hasil Perbaikan?' : 'Kirim Pengajuan Resmi?'),
        content: Text(
          isResubmit
              ? 'Seluruh perbaikan data dan berkas akan dikirim kembali ke antrean verifikator Dukcapil untuk ditinjau ulang.'
              : 'Pastikan seluruh data bayi, ibu, dan 6 berkas lampiran sudah benar. Permohonan akan masuk ke antrean verifikasi Disdukcapil.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Periksa Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isResubmit ? 'Ya, Kirim Ulang' : 'Kirim Pengajuan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiClient.dio.post('/applications/$_savedApplicationId/submit');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isResubmit
                ? 'Hasil perbaikan berhasil dikirim kembali ke Dukcapil!'
                : 'Pengajuan resmi berhasil dikirim ke antrean verifikasi Dukcapil!'),
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

  /// Buka Pratinjau Dokumen Interaktif
  void _openDocumentViewer(ApplicationDocumentModel doc, String title) {
    context.push(
      '/viewer',
      extra: {
        'title': title,
        'fileUrl': doc.fileUrl,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memuat Pengajuan...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isRevision = _applicationStatus == 'PERLU_PERBAIKAN';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isRevision ? 'Perbaikan Pengajuan (${_savedRegistrationNumber ?? ""})' : 'Pengajuan Kelahiran',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: isRevision ? Colors.amber.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Revisi jika status PERLU_PERBAIKAN
            if (isRevision) _buildRevisionAlertBanner(),

            Expanded(
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
                    padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isSavingDraft ? null : details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRevision && _currentStep == 2 ? Colors.green.shade700 : Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: _isSavingDraft
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_currentStep == 2
                                  ? (isRevision ? 'Kirim Ulang Hasil Perbaikan' : 'Kirim ke Dukcapil')
                                  : 'Simpan & Lanjut'),
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
          ],
        ),
      ),
    );
  }

  /// Banner Peringatan Revisi Resmi Disdukcapil (Modul 6: FEAT-REV-01)
  Widget _buildRevisionAlertBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
              const SizedBox(width: 8),
              Text(
                'PERMOHONAN MEMERLUKAN PERBAIKAN',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Catatan Resmi Verifikator: "${_lastRevisionNote ?? "Harap periksa isian data dan dokumen yang ditandai merah."}"',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Bidang isian bertanda merah dan dokumen yang salah wajib diperbaiki sebelum dikirim ulang.',
            style: TextStyle(color: Colors.brown.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String fieldKey,
    String? hintText,
    Widget? suffixIcon,
  }) {
    final isFlagged = _isFieldFlagged(fieldKey);
    return InputDecoration(
      labelText: isFlagged ? '$labelText (PERLU PERBAIKAN)' : labelText,
      labelStyle: isFlagged ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold) : null,
      hintText: hintText,
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isFlagged ? Colors.red : Colors.grey.shade400, width: isFlagged ? 2.0 : 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isFlagged ? Colors.red : Colors.blue.shade700, width: 2.0),
      ),
      prefixIcon: isFlagged ? const Icon(Icons.error, color: Colors.red) : null,
      suffixIcon: suffixIcon,
      helperText: isFlagged ? 'Bidang ini ditandai salah oleh verifikator Dukcapil' : null,
      helperStyle: isFlagged ? const TextStyle(color: Colors.red, fontSize: 11) : null,
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
            decoration: _buildInputDecoration(labelText: 'Nama Lengkap Bayi *', fieldKey: 'baby_name'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Nama bayi wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: _buildInputDecoration(labelText: 'Jenis Kelamin *', fieldKey: 'baby_gender'),
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
                  readOnly: true,
                  onTap: _selectBirthDate,
                  decoration: _buildInputDecoration(
                    labelText: 'Tanggal Lahir *',
                    fieldKey: 'baby_birth_date',
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _birthTimeCtrl,
                  readOnly: true,
                  onTap: _selectBirthTime,
                  decoration: _buildInputDecoration(
                    labelText: 'Jam Lahir *',
                    fieldKey: 'baby_birth_time',
                    suffixIcon: const Icon(Icons.access_time, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthPlaceCtrl,
            decoration: _buildInputDecoration(labelText: 'Tempat Lahir (RS / Puskesmas) *', fieldKey: 'baby_birth_place'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Tempat lahir wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _birthWeightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(labelText: 'Berat Lahir (Gram)', fieldKey: 'baby_weight'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _birthLengthCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(labelText: 'Panjang Lahir (Cm)', fieldKey: 'baby_length'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _birthOrder,
                  decoration: _buildInputDecoration(labelText: 'Anak Ke- (Urutan)', fieldKey: 'birth_order'),
                  items: List.generate(10, (i) => DropdownMenuItem(value: i + 1, child: Text('Anak ke-${i + 1}'))),
                  onChanged: (v) => setState(() => _birthOrder = v ?? 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: _buildInputDecoration(labelText: 'Kondisi Lahir', fieldKey: 'baby_condition'),
                  items: const [
                    DropdownMenuItem(value: 'SEHAT', child: Text('Sehat')),
                    DropdownMenuItem(value: 'KOMPLIKASI', child: Text('Komplikasi')),
                    DropdownMenuItem(value: 'MENINGGAL', child: Text('Meninggal')),
                  ],
                  onChanged: (v) => setState(() => _condition = v ?? 'SEHAT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _medicalRecordCtrl,
            decoration: _buildInputDecoration(labelText: 'Nomor Rekam Medis RS/Puskesmas', fieldKey: 'medical_record_no'),
          ),
          const SizedBox(height: 20),
          const Text('Identitas Orang Tua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motherNameCtrl,
            decoration: _buildInputDecoration(labelText: 'Nama Lengkap Ibu Kandung *', fieldKey: 'mother_name'),
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
                Expanded(
                  child: Text(
                    'Nomor Registrasi: $_savedRegistrationNumber',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        const Text(
          'Unggah 6 Berkas Dokumen Persyaratan Wajib:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Dapat menggunakan Kamera langsung atau memilih dari Galeri / Berkas PDF.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 14),
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
    final isFlagged = _isDocFlagged(docType.code);
    final docItem = _uploadedDocs[docType.code];

    return Card(
      elevation: isFlagged ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isFlagged ? Colors.red : (isUploaded ? Colors.green.shade300 : Colors.grey.shade300),
          width: isFlagged ? 2.0 : 1.0,
        ),
      ),
      child: ListTile(
        leading: Icon(
          isFlagged ? Icons.error : (isUploaded ? Icons.check_circle : Icons.upload_file),
          color: isFlagged ? Colors.red : (isUploaded ? Colors.green : Colors.grey),
          size: 28,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                docType.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isFlagged ? Colors.red.shade900 : Colors.black87,
                ),
              ),
            ),
            if (isFlagged)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                child: const Text('Wajib Ganti Berkas', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: isUploaded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Telah terunggah: ${docItem?.originalFileName ?? "Berkas lampiran"}',
                      style: TextStyle(fontSize: 11, color: isFlagged ? Colors.red : Colors.green.shade700)),
                  if (docItem != null)
                    InkWell(
                      onTap: () => _openDocumentViewer(docItem, docType.label),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('Klik untuk Pratinjau Dokumen (Zoom/Putar)', style: TextStyle(color: Colors.blue, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : const Text('Belum diunggah (Wajib)', style: TextStyle(fontSize: 11, color: Colors.red)),
        trailing: isCurrentUploading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton.icon(
                onPressed: () => _showDocumentSourcePicker(docType),
                icon: Icon(isUploaded ? Icons.sync : Icons.camera_alt, size: 16),
                label: Text(isUploaded ? 'Ganti' : 'Unggah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFlagged ? Colors.red : (isUploaded ? Colors.grey.shade200 : Colors.blue.shade600),
                  foregroundColor: isFlagged ? Colors.white : (isUploaded ? Colors.black87 : Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
      ),
    );
  }

  Widget _buildStep3Review() {
    final totalUploaded = _uploadedDocs.length;
    final isComplete = totalUploaded == 6;
    final isRevision = _applicationStatus == 'PERLU_PERBAIKAN';

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
                _buildReviewRow('Kondisi Lahir', _condition),
                _buildReviewRow('Urutan Kelahiran', 'Anak ke-$_birthOrder'),
                _buildReviewRow('Ibu Kandung', _motherNameCtrl.text),
                const Divider(),
                _buildReviewRow('Kelengkapan Dokumen', '$totalUploaded dari 6 berkas wajib terunggah'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Daftar Berkas dengan tombol pratinjau
        const Text('Daftar Berkas Terlampir (Klik untuk Pratinjau):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        for (final docType in DocumentType.values) ...[
          if (_uploadedDocs.containsKey(docType.code))
            InkWell(
              onTap: () => _openDocumentViewer(_uploadedDocs[docType.code]!, docType.label),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(docType.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    const Icon(Icons.visibility, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    const Text('Lihat', style: TextStyle(color: Colors.blue, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],

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
                      ? (isRevision
                          ? 'Perbaikan selesai. Tekan "Kirim Ulang Hasil Perbaikan" untuk memproses kembali ke Dukcapil.'
                          : 'Seluruh 6 berkas persyaratan lengkap. Anda dapat menekan tombol "Kirim ke Dukcapil".')
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
