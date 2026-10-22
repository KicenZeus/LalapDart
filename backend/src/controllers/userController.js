const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/response');

/**
 * Daftar Akun Pengguna (Admin Only)
 * GET /api/users
 */
const getUsers = async (req, res) => {
  try {
    const { role, institutionId, search } = req.query;
    const params = [];
    const whereClauses = [];

    if (role) {
      params.push(role);
      whereClauses.push(`u.role = $${params.length}`);
    }

    if (institutionId) {
      params.push(institutionId);
      whereClauses.push(`u.institution_id = $${params.length}`);
    }

    if (search) {
      params.push(`%${search.trim()}%`);
      const pIdx = params.length;
      whereClauses.push(`(u.username ILIKE $${pIdx} OR u.full_name ILIKE $${pIdx} OR u.email ILIKE $${pIdx})`);
    }

    const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

    const sql = `
      SELECT 
        u.id, u.username, u.full_name, u.role, u.institution_id, 
        i.name AS institution_name, u.nip, u.email, u.phone, u.is_active, 
        u.created_at, u.updated_at
      FROM users u
      LEFT JOIN institutions i ON u.institution_id = i.id
      ${whereSql}
      ORDER BY u.created_at DESC
    `;

    const result = await query(sql, params);
    return successResponse(res, result.rows, 'Daftar pengguna berhasil dimuat.');
  } catch (err) {
    console.error('[GET USERS ERROR]', err);
    return errorResponse(res, 'Gagal memuat pengguna: ' + err.message, 500);
  }
};

/**
 * Tambah Pengguna Baru (Admin Only)
 * POST /api/users
 */
const createUser = async (req, res) => {
  try {
    const { username, password, fullName, role, institutionId, nip, email, phone } = req.body;

    if (!username || !password || !fullName || !role) {
      return errorResponse(res, 'Username, password, nama lengkap, dan role wajib diisi.', 400);
    }

    const validRoles = ['OPERATOR_RS', 'OPERATOR_DUKCAPIL', 'ADMIN'];
    if (!validRoles.includes(role)) {
      return errorResponse(res, `Role tidak valid. Pilihan: ${validRoles.join(', ')}`, 400);
    }

    if (role === 'OPERATOR_RS' && !institutionId) {
      return errorResponse(res, 'Operator RS wajib dikaitkan dengan instansi Faskes.', 400);
    }

    // Cek duplikasi username
    const existing = await query('SELECT id FROM users WHERE username = $1', [username.trim()]);
    if (existing.rows.length > 0) {
      return errorResponse(res, `Username '${username}' sudah digunakan.`, 400);
    }

    // Ambil nama instansi
    let institutionName = null;
    if (institutionId) {
      const instRes = await query('SELECT name FROM institutions WHERE id = $1', [institutionId]);
      if (instRes.rows.length > 0) institutionName = instRes.rows[0].name;
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();

    const insertRes = await query(
      `INSERT INTO users (
         id, username, password, plain_password, full_name, role, institution_id, institution_name, nip, email, phone, is_active, created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, true, NOW(), NOW())
       RETURNING id, username, full_name, role, institution_id, institution_name, nip, email, phone, is_active, created_at`,
      [
        userId,
        username.trim(),
        hashedPassword,
        password,
        fullName.trim(),
        role,
        institutionId || null,
        institutionName,
        nip || null,
        email || null,
        phone || null,
      ]
    );

    return successResponse(res, insertRes.rows[0], 'Pengguna baru berhasil dibuat.', 201);
  } catch (err) {
    console.error('[CREATE USER ERROR]', err);
    return errorResponse(res, 'Gagal membuat pengguna: ' + err.message, 500);
  }
};

/**
 * Reset Password Pengguna (Admin Only)
 * POST /api/users/:id/reset-password
 */
const resetPassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      return errorResponse(res, 'Password baru minimal 6 karakter.', 400);
    }

    const userRes = await query('SELECT id, username FROM users WHERE id = $1', [id]);
    if (userRes.rows.length === 0) {
      return errorResponse(res, 'Pengguna tidak ditemukan.', 404);
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await query(
      `UPDATE users SET password = $1, plain_password = $2, updated_at = NOW() WHERE id = $3`,
      [hashedPassword, newPassword, id]
    );

    return successResponse(res, null, `Password pengguna '${userRes.rows[0].username}' berhasil direset.`);
  } catch (err) {
    console.error('[RESET PASS ERROR]', err);
    return errorResponse(res, 'Gagal mereset password: ' + err.message, 500);
  }
};

/**
 * Toggle Status Aktif Pengguna (Admin Only)
 * PATCH /api/users/:id/toggle-active
 */
const toggleUserActive = async (req, res) => {
  try {
    const { id } = req.params;

    if (id === req.user.id) {
      return errorResponse(res, 'Anda tidak dapat menonaktifkan akun Anda sendiri.', 400);
    }

    const userRes = await query('SELECT id, username, is_active FROM users WHERE id = $1', [id]);
    if (userRes.rows.length === 0) {
      return errorResponse(res, 'Pengguna tidak ditemukan.', 404);
    }

    const newStatus = !userRes.rows[0].is_active;

    await query('UPDATE users SET is_active = $1, updated_at = NOW() WHERE id = $2', [newStatus, id]);

    return successResponse(
      res,
      { id, isActive: newStatus },
      `Akun pengguna '${userRes.rows[0].username}' berhasil ${newStatus ? 'diaktifkan' : 'dinonaktifkan'}.`
    );
  } catch (err) {
    console.error('[TOGGLE USER ERROR]', err);
    return errorResponse(res, 'Gagal mengubah status akun: ' + err.message, 500);
  }
};

/**
 * Ubah Password Mandiri (Semua Pengguna Login)
 * POST /api/auth/change-password
 */
const changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return errorResponse(res, 'Password lama dan password baru wajib diisi.', 400);
    }

    if (newPassword.length < 6) {
      return errorResponse(res, 'Password baru minimal 6 karakter.', 400);
    }

    const userRes = await query('SELECT password FROM users WHERE id = $1', [req.user.id]);
    if (userRes.rows.length === 0) {
      return errorResponse(res, 'Pengguna tidak ditemukan.', 404);
    }

    const currentHash = userRes.rows[0].password;
    const isMatch = await bcrypt.compare(oldPassword, currentHash);
    if (!isMatch) {
      return errorResponse(res, 'Password lama yang Anda masukkan salah.', 400);
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    await query(
      `UPDATE users SET password = $1, plain_password = $2, updated_at = NOW() WHERE id = $3`,
      [newHash, newPassword, req.user.id]
    );

    return successResponse(res, null, 'Password berhasil diperbarui.');
  } catch (err) {
    console.error('[CHANGE PASS ERROR]', err);
    return errorResponse(res, 'Gagal mengubah password: ' + err.message, 500);
  }
};

module.exports = {
  getUsers,
  createUser,
  resetPassword,
  toggleUserActive,
  changePassword,
};
