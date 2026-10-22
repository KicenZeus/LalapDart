const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const { query } = require('./config/db');
const { successResponse, errorResponse } = require('./utils/response');
const { authenticateToken, authorize } = require('./middleware/auth');
const { changePassword } = require('./controllers/userController');
const { getDashboardStats } = require('./controllers/dashboardController');

// Router imports
const applicationRoutes = require('./routes/applicationRoutes');
const documentRoutes = require('./routes/documentRoutes');
const verificationRoutes = require('./routes/verificationRoutes');
const userRoutes = require('./routes/userRoutes');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5055;

// Middleware Keamanan & Log
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// 1. Health Check
app.get('/health', async (req, res) => {
  try {
    const dbTest = await query('SELECT NOW() AS server_time, current_database() AS current_db');
    return successResponse(res, {
      status: 'HEALTHY',
      service: 'LalapDart Backend API',
      database: dbTest.rows[0].current_db,
      timestamp: dbTest.rows[0].server_time,
    }, 'Backend dan Database terisolasi aktif dengan normal.');
  } catch (err) {
    return errorResponse(res, 'Database gagal terhubung: ' + err.message, 500);
  }
});

// 2. Auth Routes
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return errorResponse(res, 'Username dan kata sandi wajib diisi.', 400);
    }

    const userRes = await query(
      `SELECT u.*, i.name AS institution_real_name 
       FROM users u 
       LEFT JOIN institutions i ON u.institution_id = i.id 
       WHERE u.username = $1`,
      [username.trim()]
    );

    if (userRes.rows.length === 0) {
      return errorResponse(res, 'Username atau kata sandi salah.', 401);
    }

    const user = userRes.rows[0];

    if (!user.is_active) {
      return errorResponse(res, 'Akun Anda telah dinonaktifkan. Hubungi Admin Dukcapil.', 403);
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      if (user.plain_password && user.plain_password === password) {
        // match fallback
      } else {
        return errorResponse(res, 'Username atau kata sandi salah.', 401);
      }
    }

    const token = jwt.sign(
      {
        id: user.id,
        username: user.username,
        role: user.role,
        institution_id: user.institution_id,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    const userData = {
      id: user.id,
      username: user.username,
      fullName: user.full_name,
      role: user.role,
      institutionId: user.institution_id,
      institutionName: user.institution_real_name || user.institution_name,
      email: user.email,
      phone: user.phone,
    };

    return successResponse(res, {
      token,
      user: userData,
    }, 'Login berhasil');
  } catch (err) {
    console.error('[AUTH ERROR]', err);
    return errorResponse(res, 'Terjadi kegagalan proses login.', 500);
  }
});

app.get('/api/auth/me', authenticateToken, (req, res) => {
  return successResponse(res, {
    id: req.user.id,
    username: req.user.username,
    fullName: req.user.full_name,
    role: req.user.role,
    institutionId: req.user.institution_id,
    institutionName: req.user.institution_name,
    email: req.user.email,
  }, 'Data identitas pengguna berhasil diambil');
});

app.post('/api/auth/change-password', authenticateToken, changePassword);

// 3. Modul Pengajuan Kelahiran & Pelacakan Publik
app.use('/api/applications', applicationRoutes);

// 4. Modul Dokumen & Streaming Proxy
app.use('/api/documents', documentRoutes);

// 5. Modul Verifikasi Disdukcapil
app.use('/api/verification', verificationRoutes);

// 6. Modul Pengguna (Admin)
app.use('/api/users', userRoutes);

// 7. Modul Dashboard Statistik
app.get('/api/dashboard/stats', authenticateToken, getDashboardStats);

// 8. Master Data Institutions
app.get('/api/institutions', authenticateToken, async (req, res) => {
  try {
    const result = await query(
      'SELECT id, type, name, code, address, phone, email, is_active FROM institutions ORDER BY type ASC, name ASC'
    );
    return successResponse(res, result.rows, 'Daftar instansi berhasil diambil');
  } catch (err) {
    return errorResponse(res, 'Gagal mengambil data instansi: ' + err.message, 500);
  }
});

app.post('/api/institutions', authenticateToken, authorize(['ADMIN']), async (req, res) => {
  try {
    const { name, code, type = 'PUSKESMAS', address, phone, email } = req.body;
    if (!name || !code || !address) {
      return errorResponse(res, 'Nama, kode, dan alamat instansi wajib diisi.', 400);
    }

    const { v4: uuidv4 } = require('uuid');
    const id = `inst-${code.toLowerCase().replace(/[^a-z0-9]/g, '-')}`;

    const insertRes = await query(
      `INSERT INTO institutions (id, type, name, code, address, phone, email, is_active, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, true, NOW(), NOW())
       RETURNING *`,
      [id, type, name, code, address, phone || null, email || null]
    );

    return successResponse(res, insertRes.rows[0], 'Instansi baru berhasil ditambahkan.', 201);
  } catch (err) {
    console.error('[CREATE INST ERROR]', err);
    return errorResponse(res, 'Gagal menambah instansi: ' + err.message, 500);
  }
});

// 404 Handler
app.use((req, res) => {
  return errorResponse(res, `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`, 404);
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[SERVER ERROR]', err);
  return errorResponse(res, err.message || 'Terjadi kesalahan internal server.', 500);
});

app.listen(PORT, () => {
  console.log(`[LALAPDART SERVER] Berjalan di http://127.0.0.1:${PORT}`);
  console.log(`[LALAPDART SERVER] Database: pengajuan_mobile_db (Port 5435)`);
  console.log(`[LALAPDART SERVER] Seluruh Endpoint Fase 2 Aktif`);
});
