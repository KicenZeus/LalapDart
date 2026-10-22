const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { errorResponse } = require('../utils/response');

/**
 * Middleware Autentikasi JWT Bearer
 */
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return errorResponse(res, 'Akses ditolak. Token tidak ditemukan.', 401);
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Ambil data user terbaru dari database
    const userRes = await query(
      'SELECT id, username, full_name, role, institution_id, institution_name, is_active FROM users WHERE id = $1',
      [decoded.id]
    );

    if (userRes.rows.length === 0) {
      return errorResponse(res, 'Pengguna tidak ditemukan.', 401);
    }

    const user = userRes.rows[0];

    if (!user.is_active) {
      return errorResponse(res, 'Akun Anda dinonaktifkan oleh Administrator.', 403);
    }

    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return errorResponse(res, 'Sesi Anda telah berakhir. Silakan login kembali.', 401);
    }
    return errorResponse(res, 'Token tidak valid.', 403);
  }
};

/**
 * Middleware Role-Based Access Control (RBAC)
 */
const authorize = (allowedRoles = []) => {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Tidak terautentikasi.', 401);
    }

    if (!allowedRoles.includes(req.user.role)) {
      return errorResponse(res, 'Akses terlarang untuk peran Anda.', 403);
    }

    next();
  };
};

/**
 * Middleware Isolasi Multi-Tenancy Faskes (Rule 3)
 * OPERATOR_RS hanya boleh mengakses pengajuan dari instansinya sendiri.
 */
const verifyInstitutionAccess = (applicationInstitutionId, user) => {
  if (user.role === 'ADMIN' || user.role === 'OPERATOR_DUKCAPIL') {
    return true;
  }

  if (user.role === 'OPERATOR_RS') {
    return user.institution_id === applicationInstitutionId;
  }

  return false;
};

module.exports = {
  authenticateToken,
  authorize,
  verifyInstitutionAccess,
};
