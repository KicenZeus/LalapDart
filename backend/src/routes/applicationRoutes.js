const express = require('express');
const router = express.Router();

const { authenticateToken, authorize } = require('../middleware/auth');
const {
  createApplication,
  getApplications,
  getApplicationDetail,
  updateApplication,
  submitApplication,
  deleteApplication,
  publicTrack,
} = require('../controllers/applicationController');

// 1. Pelacakan Publik (Tanpa Login)
router.get('/public/track', publicTrack);

// 2. Daftar & Detail Pengajuan (Perlu Login)
router.get('/', authenticateToken, getApplications);
router.get('/:id', authenticateToken, getApplicationDetail);

// 3. Mutasi Pengajuan (Operator RS & Admin)
router.post('/', authenticateToken, authorize(['OPERATOR_RS', 'ADMIN']), createApplication);
router.put('/:id', authenticateToken, authorize(['OPERATOR_RS', 'ADMIN']), updateApplication);
router.post('/:id/submit', authenticateToken, authorize(['OPERATOR_RS', 'ADMIN']), submitApplication);
router.delete('/:id', authenticateToken, authorize(['OPERATOR_RS', 'ADMIN']), deleteApplication);

module.exports = router;
