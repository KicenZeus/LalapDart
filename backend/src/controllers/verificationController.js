const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/response');

/**
 * Antrean Pengajuan Menunggu Verifikasi Disdukcapil
 * GET /api/verification/queue
 */
const getVerificationQueue = async (req, res) => {
  try {
    const { institutionId, search, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const params = [];
    const whereClauses = [`a.status = 'MENUNGGU_VERIFIKASI'`];

    if (institutionId) {
      params.push(institutionId);
      whereClauses.push(`a.institution_id = $${params.length}`);
    }

    if (search) {
      params.push(`%${search.trim()}%`);
      const pIdx = params.length;
      whereClauses.push(`(
        a.registration_number ILIKE $${pIdx} OR 
        b.full_name ILIKE $${pIdx} OR 
        m.full_name ILIKE $${pIdx} OR
        a.institution_name ILIKE $${pIdx}
      )`);
    }

    const whereSql = `WHERE ${whereClauses.join(' AND ')}`;

    // Hitung total
    const countRes = await query(
      `SELECT count(*) 
       FROM applications a
       LEFT JOIN baby b ON a.id = b.application_id
       LEFT JOIN mother m ON a.id = m.application_id
       ${whereSql}`,
      params
    );
    const totalCount = parseInt(countRes.rows[0].count, 10);

    params.push(limit);
    params.push(offset);
    const dataRes = await query(
      `SELECT 
         a.id, a.pgj_number, a.registration_number, a.status, a.institution_id, a.institution_name,
         a.submitted_at, a.revision_count, a.created_at,
         b.full_name AS baby_name, b.gender AS baby_gender, b.birth_date AS baby_birth_date, b.medical_record_no,
         m.full_name AS mother_name,
         (SELECT count(*) FROM application_documents d WHERE d.application_id = a.id) AS uploaded_docs_count
       FROM applications a
       LEFT JOIN baby b ON a.id = b.application_id
       LEFT JOIN mother m ON a.id = m.application_id
       ${whereSql}
       ORDER BY a.submitted_at ASC NULLS LAST, a.created_at ASC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    return successResponse(res, {
      items: dataRes.rows,
      pagination: {
        total: totalCount,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
        totalPages: Math.ceil(totalCount / limit),
      },
    }, 'Antrean verifikasi berhasil dimuat.');
  } catch (err) {
    console.error('[VERIF QUEUE ERROR]', err);
    return errorResponse(res, 'Gagal memuat antrean verifikasi: ' + err.message, 500);
  }
};

/**
 * Permintaan Perbaikan Berkas & Checklist Field
 * POST /api/verification/:id/request-revision
 */
const requestRevision = async (req, res) => {
  try {
    const { id } = req.params;
    const { revisionNote, fieldChecklist, documentChecklist } = req.body;

    if (!revisionNote || revisionNote.trim().length === 0) {
      return errorResponse(res, 'Catatan perbaikan wajib diisi oleh verifikator.', 400);
    }

    const appRes = await query('SELECT * FROM applications WHERE id = $1', [id]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const app = appRes.rows[0];

    if (app.status !== 'MENUNGGU_VERIFIKASI') {
      return errorResponse(res, `Pengajuan hanya dapat direvisi dari status MENUNGGU_VERIFIKASI, saat ini: ${app.status}`, 400);
    }

    const revisionPayload = {
      note: revisionNote.trim(),
      fieldChecklist: fieldChecklist || [],
      documentChecklist: documentChecklist || [],
      revisedBy: req.user.full_name || req.user.username,
      revisedAt: new Date().toISOString(),
    };

    const currentNotes = app.notes || {};
    const updatedNotes = {
      ...currentNotes,
      revision: revisionPayload,
    };

    // Update status ke PERLU_PERBAIKAN dan tambah revision_count
    await query(
      `UPDATE applications SET
         status = 'PERLU_PERBAIKAN',
         verifikator_id = $1,
         last_revision_note = $2,
         revision_count = revision_count + 1,
         notes = $3,
         updated_at = NOW()
       WHERE id = $4`,
      [req.user.id, revisionNote.trim(), JSON.stringify(updatedNotes), id]
    );

    // Audit log
    await query(
      `INSERT INTO activity_logs (
         id, application_id, user_id, user_role, user_full_name, event_type, action, old_status, new_status, summary, notes, metadata_json, timestamp
       ) VALUES ($1, $2, $3, $4, $5, 'REQUEST_REVISION', 'MINTA_PERBAIKAN', 'MENUNGGU_VERIFIKASI', 'PERLU_PERBAIKAN', $6, $7, $8, NOW())`,
      [
        uuidv4(),
        id,
        req.user.id,
        req.user.role,
        req.user.full_name || req.user.username,
        `Verifikator meminta perbaikan berkas untuk faskes ${app.institution_name}.`,
        revisionNote.trim(),
        JSON.stringify(revisionPayload),
      ]
    );

    return successResponse(res, {
      id,
      status: 'PERLU_PERBAIKAN',
      revision: revisionPayload,
    }, 'Status pengajuan berhasil diubah menjadi PERLU_PERBAIKAN.');
  } catch (err) {
    console.error('[REQUEST REVISION ERROR]', err);
    return errorResponse(res, 'Gagal memproses permohonan revisi: ' + err.message, 500);
  }
};

/**
 * Setujui Pengajuan & Terbitkan Nomor Akta Kelahiran
 * POST /api/verification/:id/approve
 */
const approveApplication = async (req, res) => {
  try {
    const { id } = req.params;
    const { aktaKelahiranNumber, notes } = req.body;

    if (!aktaKelahiranNumber || aktaKelahiranNumber.trim().length === 0) {
      return errorResponse(res, 'Nomor Akta Kelahiran resmi wajib diisi saat persetujuan.', 400);
    }

    const appRes = await query('SELECT * FROM applications WHERE id = $1', [id]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const app = appRes.rows[0];

    if (app.status !== 'MENUNGGU_VERIFIKASI') {
      return errorResponse(res, `Pengajuan hanya dapat disetujui saat berstatus MENUNGGU_VERIFIKASI. Status saat ini: ${app.status}`, 400);
    }

    const cleanAktaNumber = aktaKelahiranNumber.trim();

    await query(
      `UPDATE applications SET
         status = 'DISETUJUI',
         akta_kelahiran_number = $1,
         verifikator_id = $2,
         verified_at = NOW(),
         updated_at = NOW()
       WHERE id = $3`,
      [cleanAktaNumber, req.user.id, id]
    );

    // Audit Log
    await query(
      `INSERT INTO activity_logs (
         id, application_id, user_id, user_role, user_full_name, event_type, action, old_status, new_status, summary, notes, timestamp
       ) VALUES ($1, $2, $3, $4, $5, 'APPROVE_APPLICATION', 'SETUJUI_AKTA', 'MENUNGGU_VERIFIKASI', 'DISETUJUI', $6, $7, NOW())`,
      [
        uuidv4(),
        id,
        req.user.id,
        req.user.role,
        req.user.full_name || req.user.username,
        `Permohonan disetujui sah oleh verifikator Dukcapil. No. Akta Kelahiran: ${cleanAktaNumber}`,
        notes ? notes.trim() : null,
      ]
    );

    return successResponse(res, {
      id,
      status: 'DISETUJUI',
      aktaKelahiranNumber: cleanAktaNumber,
    }, 'Permohonan persalinan berhasil disetujui dan Nomor Akta Kelahiran resmi telah diterbitkan.');
  } catch (err) {
    console.error('[APPROVE ERROR]', err);
    return errorResponse(res, 'Gagal menyetujui pengajuan: ' + err.message, 500);
  }
};

/**
 * Tolak Pengajuan Permanen
 * POST /api/verification/:id/reject
 */
const rejectApplication = async (req, res) => {
  try {
    const { id } = req.params;
    const { rejectNote } = req.body;

    if (!rejectNote || rejectNote.trim().length === 0) {
      return errorResponse(res, 'Alasan penolakan resmi wajib diisi.', 400);
    }

    const appRes = await query('SELECT * FROM applications WHERE id = $1', [id]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const app = appRes.rows[0];

    if (app.status !== 'MENUNGGU_VERIFIKASI') {
      return errorResponse(res, `Pengajuan hanya dapat ditolak saat status MENUNGGU_VERIFIKASI. Status saat ini: ${app.status}`, 400);
    }

    const cleanReason = rejectNote.trim();

    await query(
      `UPDATE applications SET
         status = 'DITOLAK',
         last_reject_note = $1,
         verifikator_id = $2,
         verified_at = NOW(),
         updated_at = NOW()
       WHERE id = $3`,
      [cleanReason, req.user.id, id]
    );

    // Audit Log
    await query(
      `INSERT INTO activity_logs (
         id, application_id, user_id, user_role, user_full_name, event_type, action, old_status, new_status, summary, notes, timestamp
       ) VALUES ($1, $2, $3, $4, $5, 'REJECT_APPLICATION', 'TOLAK_PERMOHONAN', 'MENUNGGU_VERIFIKASI', 'DITOLAK', $6, $7, NOW())`,
      [
        uuidv4(),
        id,
        req.user.id,
        req.user.role,
        req.user.full_name || req.user.username,
        `Permohonan ditolak definitif oleh verifikator Dukcapil. Alasan: ${cleanReason}`,
        cleanReason,
      ]
    );

    return successResponse(res, {
      id,
      status: 'DITOLAK',
      rejectNote: cleanReason,
    }, 'Permohonan berhasil ditolak.');
  } catch (err) {
    console.error('[REJECT ERROR]', err);
    return errorResponse(res, 'Gagal menolak pengajuan: ' + err.message, 500);
  }
};

module.exports = {
  getVerificationQueue,
  requestRevision,
  approveApplication,
  rejectApplication,
};
