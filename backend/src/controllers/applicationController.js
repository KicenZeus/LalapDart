const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/response');
const { verifyInstitutionAccess } = require('../middleware/auth');
const storageService = require('../config/storage');

const MANDATORY_DOCUMENTS = [
  'KTP_IBU',
  'KTP_AYAH',
  'KARTU_KELUARGA',
  'SURAT_KETERANGAN_LAHIR_RS',
  'BUKU_NIKAH',
  'REKAM_MEDIS_IA_DAN_BAYI',
];

/**
 * Generate Nomor Registrasi Resmi: PGJ-YYYYMM-XXX
 */
const generateRegistrationNumber = async () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const prefix = `PGJ-${year}${month}-`;

  const countRes = await query(
    `SELECT count(*) FROM applications WHERE registration_number LIKE $1`,
    [`${prefix}%`]
  );

  const nextSeq = parseInt(countRes.rows[0].count, 10) + 1;
  const seqStr = String(nextSeq).padStart(3, '0');
  return `${prefix}${seqStr}`;
};

/**
 * Buat Draf Pengajuan Baru
 * POST /api/applications
 */
const createApplication = async (req, res) => {
  try {
    const { baby, mother, notes } = req.body;

    if (!baby || !mother) {
      return errorResponse(res, 'Data Bayi dan Data Ibu wajib diisi.', 400);
    }

    if (!baby.fullName || !baby.gender || !baby.birthDate || !baby.birthTime || !baby.birthPlace) {
      return errorResponse(res, 'Kelengkapan identitas bayi (nama, gender, tanggal, jam, tempat lahir) wajib diisi.', 400);
    }

    if (!mother.fullName) {
      return errorResponse(res, 'Nama lengkap ibu kandung wajib diisi.', 400);
    }

    const regNumber = await generateRegistrationNumber();
    const applicationId = uuidv4();
    const babyId = uuidv4();
    const motherId = uuidv4();
    const operator = req.user;

    // Ambil nama instansi jika belum ada di operator
    let institutionName = operator.institution_name;
    if (!institutionName && operator.institution_id) {
      const instRes = await query('SELECT name FROM institutions WHERE id = $1', [operator.institution_id]);
      if (instRes.rows.length > 0) institutionName = instRes.rows[0].name;
    }

    // 1. Simpan tabel applications
    await query(
      `INSERT INTO applications (
         id, pgj_number, registration_number, status, operator_id, institution_id, institution_name, notes, created_at, updated_at
       ) VALUES ($1, $2, $3, 'DRAFT', $4, $5, $6, $7, NOW(), NOW())`,
      [
        applicationId,
        regNumber,
        regNumber,
        operator.id,
        operator.institution_id,
        institutionName,
        notes ? JSON.stringify(notes) : null,
      ]
    );

    // 2. Simpan tabel baby
    await query(
      `INSERT INTO baby (
         id, application_id, full_name, gender, birth_order, birth_weight_gram, birth_length_cm, birth_place, birth_date, birth_time, condition, medical_record_no, created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())`,
      [
        babyId,
        applicationId,
        baby.fullName.trim(),
        baby.gender,
        baby.birthOrder || 1,
        baby.birthWeightGram || null,
        baby.birthLengthCm || null,
        baby.birthPlace.trim(),
        baby.birthDate,
        baby.birthTime,
        baby.condition || 'SEHAT',
        baby.medicalRecordNo ? baby.medicalRecordNo.trim() : null,
      ]
    );

    // 3. Simpan tabel mother
    await query(
      `INSERT INTO mother (
         id, application_id, full_name, created_at, updated_at
       ) VALUES ($1, $2, $3, NOW(), NOW())`,
      [motherId, applicationId, mother.fullName.trim()]
    );

    // 4. Catat ke activity_logs
    await query(
      `INSERT INTO activity_logs (
         id, application_id, user_id, user_role, user_full_name, event_type, action, new_status, summary, timestamp
       ) VALUES ($1, $2, $3, $4, $5, 'CREATE_DRAFT', 'BUAT_DRAF', 'DRAFT', $6, NOW())`,
      [
        uuidv4(),
        applicationId,
        operator.id,
        operator.role,
        operator.full_name || operator.username,
        `Draf pengajuan kelahiran berhasil dibuat oleh ${operator.full_name || operator.username}.`,
      ]
    );

    return successResponse(
      res,
      {
        id: applicationId,
        registrationNumber: regNumber,
        status: 'DRAFT',
        baby: { id: babyId, ...baby },
        mother: { id: motherId, ...mother },
      },
      'Draf pengajuan kelahiran berhasil disimpan.',
      201
    );
  } catch (err) {
    console.error('[CREATE APP ERROR]', err);
    return errorResponse(res, 'Gagal membuat draf pengajuan: ' + err.message, 500);
  }
};

/**
 * Daftar Pengajuan (dengan filter Multi-Tenancy per Faskes)
 * GET /api/applications
 */
const getApplications = async (req, res) => {
  try {
    const { status, institutionId, search, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const params = [];
    const whereClauses = [];

    // Isolasi Multi-Tenancy (Rule 3)
    if (req.user.role === 'OPERATOR_RS') {
      params.push(req.user.institution_id);
      whereClauses.push(`a.institution_id = $${params.length}`);
    } else if (institutionId) {
      params.push(institutionId);
      whereClauses.push(`a.institution_id = $${params.length}`);
    }

    if (status) {
      params.push(status);
      whereClauses.push(`a.status = $${params.length}`);
    }

    if (search) {
      params.push(`%${search.trim()}%`);
      const pIdx = params.length;
      whereClauses.push(`(
        a.registration_number ILIKE $${pIdx} OR 
        a.pgj_number ILIKE $${pIdx} OR 
        b.full_name ILIKE $${pIdx} OR 
        m.full_name ILIKE $${pIdx} OR
        b.medical_record_no ILIKE $${pIdx}
      )`);
    }

    const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

    // Hitung total
    const countQuery = `
      SELECT count(*) 
      FROM applications a
      LEFT JOIN baby b ON a.id = b.application_id
      LEFT JOIN mother m ON a.id = m.application_id
      ${whereSql}
    `;
    const countRes = await query(countQuery, params);
    const totalCount = parseInt(countRes.rows[0].count, 10);

    // Ambil data
    params.push(limit);
    params.push(offset);
    const dataQuery = `
      SELECT 
        a.id, a.pgj_number, a.registration_number, a.status, a.institution_id, a.institution_name,
        a.submitted_at, a.verified_at, a.revision_count, a.akta_kelahiran_number,
        a.last_revision_note, a.last_reject_note, a.created_at, a.updated_at,
        b.full_name AS baby_name, b.gender AS baby_gender, b.birth_date AS baby_birth_date, b.medical_record_no,
        m.full_name AS mother_name,
        (SELECT count(*) FROM application_documents d WHERE d.application_id = a.id) AS uploaded_docs_count
      FROM applications a
      LEFT JOIN baby b ON a.id = b.application_id
      LEFT JOIN mother m ON a.id = m.application_id
      ${whereSql}
      ORDER BY a.created_at DESC
      LIMIT $${params.length - 1} OFFSET $${params.length}
    `;

    const dataRes = await query(dataQuery, params);

    return successResponse(
      res,
      {
        items: dataRes.rows,
        pagination: {
          total: totalCount,
          page: parseInt(page, 10),
          limit: parseInt(limit, 10),
          totalPages: Math.ceil(totalCount / limit),
        },
      },
      'Daftar pengajuan berhasil dimuat.'
    );
  } catch (err) {
    console.error('[GET APPS ERROR]', err);
    return errorResponse(res, 'Gagal memuat daftar pengajuan: ' + err.message, 500);
  }
};

/**
 * Detail Pengajuan Lengkap (Bayi, Ibu, Dokumen, & Checklist Wajib)
 * GET /api/applications/:id
 */
const getApplicationDetail = async (req, res) => {
  try {
    const { id } = req.params;

    const appRes = await query('SELECT * FROM applications WHERE id = $1', [id]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const application = appRes.rows[0];

    // Cek multi-tenancy
    if (!verifyInstitutionAccess(application.institution_id, req.user)) {
      return errorResponse(res, 'Akses ditolak. Anda tidak berhak melihat data faskes lain.', 403);
    }

    // Ambil data Bayi
    const babyRes = await query('SELECT * FROM baby WHERE application_id = $1', [id]);
    // Ambil data Ibu
    const motherRes = await query('SELECT * FROM mother WHERE application_id = $1', [id]);
    // Ambil Dokumen
    const docRes = await query('SELECT * FROM application_documents WHERE application_id = $1 ORDER BY uploaded_at ASC', [id]);
    // Ambil Riwayat Logs
    const logRes = await query('SELECT * FROM activity_logs WHERE application_id = $1 ORDER BY timestamp DESC LIMIT 20', [id]);

    const uploadedDocTypes = docRes.rows.map((d) => d.document_type);
    const missingDocs = MANDATORY_DOCUMENTS.filter((docType) => !uploadedDocTypes.includes(docType));

    return successResponse(res, {
      application,
      baby: babyRes.rows[0] || null,
      mother: motherRes.rows[0] || null,
      documents: docRes.rows,
      logs: logRes.rows,
      checklist: {
        totalMandatory: MANDATORY_DOCUMENTS.length,
        uploadedCount: docRes.rows.length,
        isComplete: missingDocs.length === 0,
        missingDocuments: missingDocs,
      },
    }, 'Detail pengajuan berhasil dimuat.');
  } catch (err) {
    console.error('[DETAIL APP ERROR]', err);
    return errorResponse(res, 'Gagal memuat detail pengajuan: ' + err.message, 500);
  }
};

/**
 * Perbarui Data Draf Pengajuan
 * PUT /api/applications/:id
 */
const updateApplication = async (req, res) => {
  try {
    const { id } = req.params;
    const { baby, mother, notes } = req.body;

    const appRes = await query('SELECT * FROM applications WHERE id = $1', [id]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const application = appRes.rows[0];

    if (!verifyInstitutionAccess(application.institution_id, req.user)) {
      return errorResponse(res, 'Akses ditolak.', 403);
    }

    if (!['DRAFT', 'PERLU_PERBAIKAN'].includes(application.status)) {
      return errorResponse(res, `Pengajuan tidak dapat diedit saat berstatus '${application.status}'.`, 400);
    }

    // Update baby
    if (baby) {
      await query(
        `UPDATE baby SET
           full_name = COALESCE($1, full_name),
           gender = COALESCE($2, gender),
           birth_order = COALESCE($3, birth_order),
           birth_weight_gram = COALESCE($4, birth_weight_gram),
           birth_length_cm = COALESCE($5, birth_length_cm),
           birth_place = COALESCE($6, birth_place),
           birth_date = COALESCE($7, birth_date),
           birth_time = COALESCE($8, birth_time),
           condition = COALESCE($9, condition),
           medical_record_no = COALESCE($10, medical_record_no),
           updated_at = NOW()
         WHERE application_id = $11`,
        [
          baby.fullName,
          baby.gender,
          baby.birthOrder,
          baby.birthWeightGram,
          baby.birthLengthCm,
          baby.birthPlace,
          baby.birthDate,
          baby.birthTime,
          baby.condition,
          baby.medicalRecordNo,
          id,
        ]
      );
    }

    // Update mother
    if (mother && mother.fullName) {
      await query(
        `UPDATE mother SET full_name = $1, updated_at = NOW() WHERE application_id = $2`,
        [mother.fullName.trim(), id]
      );
    }

    // Update application notes & updated_at
    await query(
      `UPDATE applications SET
         notes = COALESCE($1, notes),
         updated_at = NOW()
       WHERE id = $2`,
      [notes ? JSON.stringify(notes) : null, id]
    );

    return successResponse(res, null, 'Data pengajuan berhasil diperbarui.');
  } catch (err) {
    console.error('[UPDATE APP ERROR]', err);
    return errorResponse(res, 'Gagal memperbarui data pengajuan: ' + err.message, 500);
  }
};

/**
 * Kirim Pengajuan ke Verifikasi Dukcapil (Wajib 6 Dokumen Lengkap)
 * POST /api/applications/:id/submit
 */
const submitApplication = async (req, res) => {
  try {
    const { id } = req.params;

    const appRes = await query('SELECT * FROM applications WHERE id = $1', [id]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const application = appRes.rows[0];

    if (!verifyInstitutionAccess(application.institution_id, req.user)) {
      return errorResponse(res, 'Akses ditolak.', 403);
    }

    if (!['DRAFT', 'PERLU_PERBAIKAN'].includes(application.status)) {
      return errorResponse(res, `Pengajuan berstatus '${application.status}' tidak dapat dikirim ulang.`, 400);
    }

    // Validasi 6 Dokumen Wajib
    const docRes = await query('SELECT document_type FROM application_documents WHERE application_id = $1', [id]);
    const uploadedTypes = docRes.rows.map((d) => d.document_type);
    const missingDocs = MANDATORY_DOCUMENTS.filter((type) => !uploadedTypes.includes(type));

    if (missingDocs.length > 0) {
      return errorResponse(
        res,
        `Pengajuan belum dapat dikirim. Masih ada ${missingDocs.length} dokumen wajib yang belum diunggah: ${missingDocs.join(', ')}`,
        400,
        { missingDocuments: missingDocs }
      );
    }

    const prevStatus = application.status;
    const isResubmission = prevStatus === 'PERLU_PERBAIKAN';

    // Update status ke MENUNGGU_VERIFIKASI
    await query(
      `UPDATE applications 
       SET status = 'MENUNGGU_VERIFIKASI', submitted_at = NOW(), updated_at = NOW() 
       WHERE id = $1`,
      [id]
    );

    // Audit Trail
    await query(
      `INSERT INTO activity_logs (
         id, application_id, user_id, user_role, user_full_name, event_type, action, old_status, new_status, summary, timestamp
       ) VALUES ($1, $2, $3, $4, $5, 'SUBMIT_APPLICATION', $6, $7, 'MENUNGGU_VERIFIKASI', $8, NOW())`,
      [
        uuidv4(),
        id,
        req.user.id,
        req.user.role,
        req.user.full_name || req.user.username,
        isResubmission ? 'KIRIM_ULANG_PERBAIKAN' : 'KIRIM_PENGAJUAN',
        prevStatus,
        isResubmission
          ? `Perbaikan dokumen dan data telah dikirim ulang oleh ${req.user.full_name || req.user.username} ke Disdukcapil.`
          : `Seluruh 6 dokumen lengkap. Permohonan resmi dikirimkan oleh ${req.user.full_name || req.user.username} ke antrean Disdukcapil.`,
      ]
    );

    return successResponse(
      res,
      {
        id,
        status: 'MENUNGGU_VERIFIKASI',
        registrationNumber: application.registration_number,
      },
      'Permohonan berhasil dikirim ke antrean verifikasi Disdukcapil.'
    );
  } catch (err) {
    console.error('[SUBMIT APP ERROR]', err);
    return errorResponse(res, 'Gagal mengirim pengajuan: ' + err.message, 500);
  }
};

/**
 * Hapus Draf Pengajuan
 * DELETE /api/applications/:id
 */
const deleteApplication = async (req, res) => {
  try {
    const { id } = req.params;

    const appRes = await query('SELECT * FROM applications WHERE id = $1', [id]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const application = appRes.rows[0];

    if (!verifyInstitutionAccess(application.institution_id, req.user)) {
      return errorResponse(res, 'Akses ditolak.', 403);
    }

    if (application.status !== 'DRAFT') {
      return errorResponse(res, 'Hanya permohonan berstatus DRAFT yang dapat dihapus.', 400);
    }

    // Hapus seluruh file di storage
    const docsRes = await query('SELECT storage_key FROM application_documents WHERE application_id = $1', [id]);
    for (const doc of docsRes.rows) {
      await storageService.deleteFile(doc.storage_key);
    }

    // CASCADE delete menghapus baby, mother, application_documents, activity_logs
    await query('DELETE FROM applications WHERE id = $1', [id]);

    return successResponse(res, null, 'Draf pengajuan berhasil dihapus.');
  } catch (err) {
    console.error('[DELETE APP ERROR]', err);
    return errorResponse(res, 'Gagal menghapus draf pengajuan: ' + err.message, 500);
  }
};

/**
 * Modul Pelacakan Publik (Tanpa Autentikasi Login)
 * GET /api/applications/public/track?q=...
 */
const publicTrack = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length === 0) {
      return errorResponse(res, 'Nomor Registrasi atau Nama Bayi/Ibu wajib dimasukkan.', 400);
    }

    const searchParam = `%${q.trim()}%`;
    const trackQuery = `
      SELECT 
        a.id, a.registration_number, a.status, a.institution_name,
        a.submitted_at, a.verified_at, a.akta_kelahiran_number, a.revision_count,
        b.full_name AS baby_name,
        m.full_name AS mother_name,
        a.created_at
      FROM applications a
      LEFT JOIN baby b ON a.id = b.application_id
      LEFT JOIN mother m ON a.id = m.application_id
      WHERE (
        a.registration_number ILIKE $1 OR
        a.pgj_number ILIKE $1 OR
        b.full_name ILIKE $1 OR
        m.full_name ILIKE $1
      )
      ORDER BY a.created_at DESC
      LIMIT 10
    `;

    const result = await query(trackQuery, [searchParam]);

    if (result.rows.length === 0) {
      return errorResponse(res, 'Data permohonan tidak ditemukan dengan kata kunci tersebut.', 404);
    }

    const formattedResults = result.rows.map((row) => {
      // Bentuk Linimasa visual (Timeline)
      const isDraft = row.status === 'DRAFT';
      const isSubmitted = ['MENUNGGU_VERIFIKASI', 'PERLU_PERBAIKAN', 'DISETUJUI', 'DITOLAK'].includes(row.status);
      const isVerif = ['DISETUJUI', 'DITOLAK'].includes(row.status);
      const isApproved = row.status === 'DISETUJUI';

      const timeline = [
        {
          step: 1,
          title: 'Draf Pengajuan Faskes',
          description: `Dibuat di ${row.institution_name}`,
          status: 'COMPLETED',
          timestamp: row.created_at,
        },
        {
          step: 2,
          title: 'Pengiriman Berkas Medis',
          description: isSubmitted ? '6 Berkas persyaratan lengkap & terkirim ke Dukcapil' : 'Menunggu operator melengkapi berkas',
          status: isSubmitted ? 'COMPLETED' : 'PENDING',
          timestamp: row.submitted_at,
        },
        {
          step: 3,
          title: 'Verifikasi Disdukcapil',
          description: row.status === 'PERLU_PERBAIKAN'
            ? 'Terdapat catatan revisi berkas. Silakan koordinasi dengan pihak Faskes pengaju.'
            : row.status === 'DITOLAK'
            ? 'Permohonan ditolak oleh verifikator Dukcapil.'
            : isVerif
            ? 'Berkas telah divalidasi sah oleh Dukcapil.'
            : isSubmitted
            ? 'Sedang dalam antrean pemeriksaan verifikator Dukcapil'
            : 'Menunggu permohonan dikirimkan',
          status: row.status === 'PERLU_PERBAIKAN' ? 'REVISION_REQUIRED' : isVerif ? 'COMPLETED' : isSubmitted ? 'IN_PROGRESS' : 'PENDING',
          timestamp: row.verified_at,
        },
        {
          step: 4,
          title: 'Penerbitan Akta Kelahiran',
          description: isApproved
            ? `Nomor Akta Kelahiran Resmi: ${row.akta_kelahiran_number}`
            : 'Menunggu verifikasi selesai',
          status: isApproved ? 'COMPLETED' : 'PENDING',
          timestamp: isApproved ? row.verified_at : null,
        },
      ];

      return {
        registrationNumber: row.registration_number,
        status: row.status,
        babyName: row.baby_name,
        motherName: row.mother_name,
        institutionName: row.institution_name,
        aktaKelahiranNumber: row.akta_kelahiran_number,
        timeline,
        publicInstruction: row.status === 'PERLU_PERBAIKAN'
          ? `Permohonan memerlukan perbaikan berkas. Harap segera menghubungi fasilitas kesehatan pengaju (${row.institution_name}) untuk melengkapi berkas.`
          : null,
      };
    });

    return successResponse(res, formattedResults, 'Status pelacakan berhasil ditemukan.');
  } catch (err) {
    console.error('[PUBLIC TRACK ERROR]', err);
    return errorResponse(res, 'Gagal melacak permohonan: ' + err.message, 500);
  }
};

module.exports = {
  createApplication,
  getApplications,
  getApplicationDetail,
  updateApplication,
  submitApplication,
  deleteApplication,
  publicTrack,
};
