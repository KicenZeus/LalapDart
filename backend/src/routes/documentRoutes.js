const express = require('express');
const router = express.Router();

const { authenticateToken } = require('../middleware/auth');
const upload = require('../middleware/upload');
const {
  uploadDocument,
  viewDocument,
  downloadZip,
  deleteDocument,
} = require('../controllers/documentController');

// 1. Upload Berkas
router.post('/upload', authenticateToken, upload.single('file'), uploadDocument);

// 2. Streaming Proxy Pratinjau Dokumen
router.get('/view/:id', viewDocument);

// 3. Download Zip Semua Berkas
router.get('/:applicationId/download-zip', authenticateToken, downloadZip);

// 4. Hapus Berkas
router.delete('/:id', authenticateToken, deleteDocument);

module.exports = router;
