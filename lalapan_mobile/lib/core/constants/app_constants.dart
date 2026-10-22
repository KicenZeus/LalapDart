/// Peran Pengguna (RBAC)
enum UserRole {
  operatorRs('OPERATOR_RS', 'Operator Faskes / Bidan'),
  operatorDukcapil('OPERATOR_DUKCAPIL', 'Verifikator Disdukcapil'),
  admin('ADMIN', 'Super Administrator');

  final String code;
  final String label;
  const UserRole(this.code, this.label);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => UserRole.operatorRs,
    );
  }
}

/// 5 Siklus Status Permohonan Resmi
enum ApplicationStatus {
  draft('DRAFT', 'Draf Awal'),
  menungguVerifikasi('MENUNGGU_VERIFIKASI', 'Menunggu Verifikasi'),
  perluPerbaikan('PERLU_PERBAIKAN', 'Perlu Perbaikan'),
  disetujui('DISETUJUI', 'Disetujui'),
  ditolak('DITOLAK', 'Ditolak');

  final String code;
  final String label;
  const ApplicationStatus(this.code, this.label);

  static ApplicationStatus fromCode(String code) {
    return ApplicationStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ApplicationStatus.draft,
    );
  }
}

/// 6 Dokumen Wajib Persyaratan Pelaporan Persalinan
enum DocumentType {
  ktpIbu('KTP_IBU', 'KTP Elektronik Ibu Kandung'),
  ktpAyah('KTP_AYAH', 'KTP Elektronik Ayah Kandung'),
  kartuKeluarga('KARTU_KELUARGA', 'Kartu Keluarga Terdaftar'),
  suratKeteranganLahirRs('SURAT_KETERANGAN_LAHIR_RS', 'Surat Keterangan Lahir RS/Puskesmas'),
  bukuNikah('BUKU_NIKAH', 'Buku Nikah / Akta Perkawinan'),
  rekamMedisIaDanBayi('REKAM_MEDIS_IA_DAN_BAYI', 'Resume Rekam Medis Persalinan');

  final String code;
  final String label;
  const DocumentType(this.code, this.label);

  static DocumentType fromCode(String code) {
    return DocumentType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => DocumentType.ktpIbu,
    );
  }
}
