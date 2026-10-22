class BabyModel {
  final String? id;
  final String fullName;
  final String gender;
  final int birthOrder;
  final int? birthWeightGram;
  final double? birthLengthCm;
  final String birthPlace;
  final String birthDate;
  final String birthTime;
  final String condition;
  final String? medicalRecordNo;

  BabyModel({
    this.id,
    required this.fullName,
    required this.gender,
    required this.birthOrder,
    this.birthWeightGram,
    this.birthLengthCm,
    required this.birthPlace,
    required this.birthDate,
    required this.birthTime,
    this.condition = 'SEHAT',
    this.medicalRecordNo,
  });

  factory BabyModel.fromJson(Map<String, dynamic> json) {
    return BabyModel(
      id: json['id'],
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      gender: json['gender'] ?? 'LAKI_LAKI',
      birthOrder: json['birth_order'] ?? json['birthOrder'] ?? 1,
      birthWeightGram: json['birth_weight_gram'] ?? json['birthWeightGram'],
      birthLengthCm: json['birth_length_cm'] != null ? double.tryParse(json['birth_length_cm'].toString()) : null,
      birthPlace: json['birth_place'] ?? json['birthPlace'] ?? '',
      birthDate: json['birth_date'] ?? json['birthDate'] ?? '',
      birthTime: json['birth_time'] ?? json['birthTime'] ?? '',
      condition: json['condition'] ?? 'SEHAT',
      medicalRecordNo: json['medical_record_no'] ?? json['medicalRecordNo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'gender': gender,
      'birthOrder': birthOrder,
      'birthWeightGram': birthWeightGram,
      'birthLengthCm': birthLengthCm,
      'birthPlace': birthPlace,
      'birthDate': birthDate,
      'birthTime': birthTime,
      'condition': condition,
      'medicalRecordNo': medicalRecordNo,
    };
  }
}

class MotherModel {
  final String? id;
  final String fullName;

  MotherModel({
    this.id,
    required this.fullName,
  });

  factory MotherModel.fromJson(Map<String, dynamic> json) {
    return MotherModel(
      id: json['id'],
      fullName: json['full_name'] ?? json['fullName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
    };
  }
}

class ApplicationDocumentModel {
  final String id;
  final String applicationId;
  final String documentType;
  final String fileName;
  final String? originalFileName;
  final String fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String uploadedAt;

  ApplicationDocumentModel({
    required this.id,
    required this.applicationId,
    required this.documentType,
    required this.fileName,
    this.originalFileName,
    required this.fileUrl,
    this.fileSize,
    this.mimeType,
    required this.uploadedAt,
  });

  factory ApplicationDocumentModel.fromJson(Map<String, dynamic> json) {
    return ApplicationDocumentModel(
      id: json['id'] ?? '',
      applicationId: json['application_id'] ?? json['applicationId'] ?? '',
      documentType: json['document_type'] ?? json['documentType'] ?? '',
      fileName: json['file_name'] ?? json['fileName'] ?? '',
      originalFileName: json['original_file_name'] ?? json['originalFileName'],
      fileUrl: json['file_url'] ?? json['fileUrl'] ?? '',
      fileSize: json['file_size'] != null ? int.tryParse(json['file_size'].toString()) : null,
      mimeType: json['mime_type'] ?? json['mimeType'],
      uploadedAt: json['uploaded_at'] ?? json['uploadedAt'] ?? '',
    );
  }
}

class ApplicationModel {
  final String id;
  final String? pgjNumber;
  final String registrationNumber;
  final String status;
  final String? institutionId;
  final String? institutionName;
  final String? submittedAt;
  final String? verifiedAt;
  final String? lastRevisionNote;
  final String? lastRejectNote;
  final int revisionCount;
  final String? aktaKelahiranNumber;
  final Map<String, dynamic>? notes;
  final String createdAt;
  final String updatedAt;
  final BabyModel? baby;
  final MotherModel? mother;
  final List<ApplicationDocumentModel>? documents;

  ApplicationModel({
    required this.id,
    this.pgjNumber,
    required this.registrationNumber,
    required this.status,
    this.institutionId,
    this.institutionName,
    this.submittedAt,
    this.verifiedAt,
    this.lastRevisionNote,
    this.lastRejectNote,
    this.revisionCount = 0,
    this.aktaKelahiranNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.baby,
    this.mother,
    this.documents,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] ?? '',
      pgjNumber: json['pgj_number'] ?? json['pgjNumber'],
      registrationNumber: json['registration_number'] ?? json['registrationNumber'] ?? '',
      status: json['status'] ?? 'DRAFT',
      institutionId: json['institution_id'] ?? json['institutionId'],
      institutionName: json['institution_name'] ?? json['institutionName'],
      submittedAt: json['submitted_at'] ?? json['submittedAt'],
      verifiedAt: json['verified_at'] ?? json['verifiedAt'],
      lastRevisionNote: json['last_revision_note'] ?? json['lastRevisionNote'],
      lastRejectNote: json['last_reject_note'] ?? json['lastRejectNote'],
      revisionCount: json['revision_count'] ?? json['revisionCount'] ?? 0,
      aktaKelahiranNumber: json['akta_kelahiran_number'] ?? json['aktaKelahiranNumber'],
      notes: json['notes'] is Map<String, dynamic> ? json['notes'] : null,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      updatedAt: json['updated_at'] ?? json['updatedAt'] ?? '',
      baby: json['baby'] != null
          ? BabyModel.fromJson(json['baby'])
          : (json['baby_name'] != null
              ? BabyModel(
                  fullName: json['baby_name'],
                  gender: json['baby_gender'] ?? 'LAKI_LAKI',
                  birthOrder: 1,
                  birthPlace: '',
                  birthDate: json['baby_birth_date'] ?? '',
                  birthTime: '',
                  medicalRecordNo: json['medical_record_no'],
                )
              : null),
      mother: json['mother'] != null
          ? MotherModel.fromJson(json['mother'])
          : (json['mother_name'] != null ? MotherModel(fullName: json['mother_name']) : null),
      documents: json['documents'] != null
          ? (json['documents'] as List).map((d) => ApplicationDocumentModel.fromJson(d)).toList()
          : null,
    );
  }
}
