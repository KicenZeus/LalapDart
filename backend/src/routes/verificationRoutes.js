const express = require('express');
const router = express.Router();

const { authenticateToken, authorize } = require('../middleware/auth');
const {
  getVerificationQueue,
  requestRevision,
  approveApplication,
  rejectApplication,
} = require('../controllers/verificationController');

// Seluruh aksi verifikasi dibatasi hanya untuk verifikator Disdukcapil dan Super Admin
router.use(authenticateToken, authorize(['OPERATOR_DUKCAPIL', 'ADMIN']));

router.get('/queue', getVerificationQueue);
router.post('/:id/request-revision', requestRevision);
router.post('/:id/approve', approveApplication);
router.post('/:id/reject', rejectApplication);

module.exports = router;
