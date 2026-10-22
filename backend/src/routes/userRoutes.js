const express = require('express');
const router = express.Router();

const { authenticateToken, authorize } = require('../middleware/auth');
const {
  getUsers,
  createUser,
  resetPassword,
  toggleUserActive,
} = require('../controllers/userController');

// Seluruh aksi manajemen user dibatasi khusus Super Admin
router.use(authenticateToken, authorize(['ADMIN']));

router.get('/', getUsers);
router.post('/', createUser);
router.post('/:id/reset-password', resetPassword);
router.patch('/:id/toggle-active', toggleUserActive);

module.exports = router;
