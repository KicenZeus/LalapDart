const path = require('path');
const fs = require('fs');
const archiver = require('archiver');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');

const { query } = require('../config/db');
const storageService = require('../config/storage');
const { successResponse, errorResponse } = require('../utils/response');
const { verifyInstitutionAccess } = require('../middleware/auth');

const VALID_DOCUMENT_TYPES = [
  'KTP_IBU',
  'KTP_AYAH',
  'KARTU_KELUARGA',
  'SURAT_KETERANGAN_LAHIR_RS',
  'BUKU_NIKAH',
  'REKAM_MEDIS_IA_DAN_BAYI',
];

/**
 * Upload 1 Dokumen Persyaratan
 * POST /api/documents/upload
 */
const uploadDocument = async (req, res) => {
  try {
    const { applicationId, documentType } = req.body;
    const file = req.file;

    if (!file) {
      return errorResponse(res, 'Berkas dokumen wajib diunggah.', 400);
    }

    if (!applicationId || !documentType) {
      return errorResponse(res, 'applicationId dan documentType wajib disertakan.', 400);
    }

    if (!VALID_DOCUMENT_TYPES.includes(documentType)) {
      return errorResponse(res, `Tipe dokumen tidak valid. Pilihan: ${VALID_DOCUMENT_TYPES.join(', ')}`, 400);
    }

    // 1. Ambil data pengajuan untuk validasi izin & status
    const appRes = await query('SELECT * FROM applications WHERE id = $1', [applicationId]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const application = appRes.rows[0];

    // Cek multi-tenancy access
    if (!verifyInstitutionAccess(application.institution_id, req.user)) {
      return errorResponse(res, 'Akses ditolak. Anda tidak memiliki izin untuk pengajuan instansi ini.', 403);
    }

    // Dokumen hanya boleh diunggah jika status DRAFT atau PERLU_PERBAIKAN
    if (!['DRAFT', 'PERLU_PERBAIKAN'].includes(application.status)) {
      return errorResponse(res, `Dokumen tidak dapat diubah pada status '${application.status}'.`, 400);
    }

    const registrationNumber = application.registration_number || application.pgj_number || 'TEMP_REG';

    // 2. Simpan file fisik melalui Storage Service
    const saved = await storageService.saveFile({
      registrationNumber,
      documentType,
      originalName: file.originalname,
      buffer: file.buffer,
    });

    const docId = uuidv4();
    const fileUrl = `/api/documents/view/${docId}`;

    // 3. Simpan ke database (Upsert: jika sudah ada tipe dokumen sama di pengajuan ini, replace)
    const existingDoc = await query(
      'SELECT id, storage_key FROM application_documents WHERE application_id = $1 AND document_type = $2',
      [applicationId, documentType]
    );

    if (existingDoc.rows.length > 0) {
      // Hapus berkas lama di storage jika ada
      await storageService.deleteFile(existingDoc.rows[0].storage_key);

      const updateRes = await query(
        `UPDATE application_documents 
         SET file_name = $1, original_file_name = $2, file_url = $3, storage_key = $4, file_size = $5, mime_type = $6, uploader_id = $7, uploaded_at = NOW(), updated_at = NOW()
         WHERE id = $8
         RETURNING *`,
        [
          saved.fileName,
          file.originalname,
          fileUrl,
          saved.storageKey,
          saved.fileSize,
          file.mimetype,
          req.user.id,
          existingDoc.rows[0].id,
        ]
      );

      return successResponse(res, updateRes.rows[0], `Dokumen ${documentType} berhasil diperbarui.`);
    } else {
      const insertRes = await query(
        `INSERT INTO application_documents (
           id, application_id, document_type, file_name, original_file_name, file_url, storage_key, file_size, mime_type, uploader_id, uploaded_at, created_at, updated_at
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW(), NOW())
         RETURNING *`,
        [
          docId,
          applicationId,
          documentType,
          saved.fileName,
          file.originalname,
          fileUrl,
          saved.storageKey,
          saved.fileSize,
          file.mimetype,
          req.user.id,
        ]
      );

      return successResponse(res, insertRes.rows[0], `Dokumen ${documentType} berhasil diunggah.`);
    }
  } catch (err) {
    console.error('[UPLOAD ERROR]', err);
    return errorResponse(res, 'Gagal mengunggah dokumen: ' + err.message, 500);
  }
};

/**
 * Streaming Proxy Pratinjau Dokumen (Inline Stream)
 * GET /api/documents/view/:id
 * Mendukung autentikasi via Header Bearer atau query string `?token=...`
 */
const viewDocument = async (req, res) => {
  try {
    const { id } = req.params;

    // Ambil metadata dokumen dari database
    const docRes = await query(
      `SELECT d.*, a.institution_id 
       FROM application_documents d
       JOIN applications a ON d.application_id = a.id
       WHERE d.id = $1`,
      [id]
    );

    if (docRes.rows.length === 0) {
      return res.status(404).send('Dokumen tidak ditemukan.');
    }

    const doc = docRes.rows[0];

    // Verifikasi Token (Header atau Query Token)
    let user = req.user;
    if (!user) {
      const queryToken = req.query.token;
      if (queryToken) {
        try {
          const decoded = jwt.verify(queryToken, process.env.JWT_SECRET);
          user = decoded;
        } catch (e) {
          return res.status(401).send('Token sesi pratinjau tidak valid atau kedaluwarsa.');
        }
      }
    }

    // Jika ada user login, cek izin multi-tenancy
    if (user && user.role === 'OPERATOR_RS' && user.institution_id !== doc.institution_id) {
      return res.status(403).send('Akses terlarang. Anda tidak memiliki hak melihat dokumen faskes lain.');
    }

    const filePath = storageService.getFilePath(doc.storage_key);
    if (!filePath || !fs.existsSync(filePath)) {
      return res.status(404).send('Berkas fisik dokumen tidak ditemukan pada penyimpanan.');
    }

    // Set Header untuk inline display (PDF & Gambar)
    res.setHeader('Content-Type', doc.mime_type || 'application/octet-stream');
    res.setHeader('Content-Disposition', `inline; filename="${doc.original_file_name || doc.file_name}"`);
    res.setHeader('Content-Length', doc.file_size || fs.statSync(filePath).size);

    const stream = fs.createReadStream(filePath);
    stream.pipe(res);
  } catch (err) {
    console.error('[VIEW ERROR]', err);
    return res.status(500).send('Terjadi kesalahan saat memuat berkas.');
  }
};

/**
 * Unduh Paket Arsip ZIP Seluruh Berkas Pengajuan
 * GET /api/documents/:applicationId/download-zip
 */
const downloadZip = async (req, res) => {
  try {
    const { applicationId } = req.params;

    const appRes = await query('SELECT * FROM applications WHERE id = $1', [applicationId]);
    if (appRes.rows.length === 0) {
      return errorResponse(res, 'Pengajuan tidak ditemukan.', 404);
    }

    const application = appRes.rows[0];

    if (!verifyInstitutionAccess(application.institution_id, req.user)) {
      return errorResponse(res, 'Akses ditolak ke pengajuan ini.', 403);
    }

    // Ambil seluruh dokumen pengajuan ini
    const docsRes = await query(
      'SELECT * FROM application_documents WHERE application_id = $1 ORDER BY created_at ASC',
      [applicationId]
    );

    if (docsRes.rows.length === 0) {
      return errorResponse(res, 'Belum ada dokumen yang diunggah untuk pengajuan ini.', 400);
    }

    const regNo = application.registration_number || application.pgj_number || 'BERKAS';
    const zipName = `BERKAS_${regNo}.zip`;

    res.setHeader('Content-Type', 'application/zip');
    res.setHeader('Content-Disposition', `attachment; filename="${zipName}"`);

    const archive = archiver('zip', { zlib: { level: 9 } });

    archive.on('error', (err) => {
      console.error('[ZIP ERROR]', err);
      res.status(500).send({ error: err.message });
    });

    archive.pipe(res);

    for (const doc of docsRes.rows) {
      const filePath = storageService.getFilePath(doc.storage_key);
      if (filePath && fs.existsSync(filePath)) {
        const fileExt = path.extname(doc.original_file_name || doc.file_name) || '.jpg';
        const zipEntryName = `${doc.document_type}${fileExt}`;
        archive.file(filePath, { name: zipEntryName });
      }
    }

    await archive.finalize();
  } catch (err) {
    console.error('[DOWNLOAD ZIP ERROR]', err);
    return errorResponse(res, 'Gagal mengunduh arsip zip: ' + err.message, 500);
  }
};

/**
 * Hapus 1 Dokumen Persyaratan
 * DELETE /api/documents/:id
 */
const deleteDocument = async (req, res) => {
  try {
    const { id } = req.params;

    const docRes = await query(
      `SELECT d.*, a.institution_id, a.status 
       FROM application_documents d
       JOIN applications a ON d.application_id = a.id
       WHERE d.id = $1`,
      [id]
    );

    if (docRes.rows.length === 0) {
      return errorResponse(res, 'Dokumen tidak ditemukan.', 404);
    }

    const doc = docRes.rows[0];

    if (!verifyInstitutionAccess(doc.institution_id, req.user)) {
      return errorResponse(res, 'Akses ditolak.', 403);
    }

    if (!['DRAFT', 'PERLU_PERBAIKAN'].includes(doc.status)) {
      return errorResponse(res, `Dokumen tidak dapat dihapus pada status '${doc.status}'.`, 400);
    }

    await storageService.deleteFile(doc.storage_key);
    await query('DELETE FROM application_documents WHERE id = $1', [id]);

    return successResponse(res, null, 'Dokumen berhasil dihapus.');
  } catch (err) {
    console.error('[DELETE DOC ERROR]', err);
    return errorResponse(res, 'Gagal menghapus dokumen: ' + err.message, 500);
  }
};

module.exports = {
  uploadDocument,
  viewDocument,
  downloadZip,
  deleteDocument,
  VALID_DOCUMENT_TYPES,
};
