const { query } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/response');

/**
 * Dashboard Statistik Pengajuan
 * GET /api/dashboard/stats
 */
const getDashboardStats = async (req, res) => {
  try {
    const params = [];
    let whereSql = '';

    if (req.user.role === 'OPERATOR_RS') {
      params.push(req.user.institution_id);
      whereSql = 'WHERE institution_id = $1';
    }

    const statsSql = `
      SELECT
        count(*) AS total,
        count(*) FILTER (WHERE status = 'DRAFT') AS draft,
        count(*) FILTER (WHERE status = 'MENUNGGU_VERIFIKASI') AS menunggu_verifikasi,
        count(*) FILTER (WHERE status = 'PERLU_PERBAIKAN') AS perlu_perbaikan,
        count(*) FILTER (WHERE status = 'DISETUJUI') AS disetujui,
        count(*) FILTER (WHERE status = 'DITOLAK') AS ditolak
      FROM applications
      ${whereSql}
    `;

    const result = await query(statsSql, params);
    const row = result.rows[0];

    const stats = {
      total: parseInt(row.total, 10),
      draft: parseInt(row.draft, 10),
      menungguVerifikasi: parseInt(row.menunggu_verifikasi, 10),
      perluPerbaikan: parseInt(row.perlu_perbaikan, 10),
      disetujui: parseInt(row.disetujui, 10),
      ditolak: parseInt(row.ditolak, 10),
    };

    return successResponse(res, stats, 'Statistik dashboard berhasil diambil.');
  } catch (err) {
    console.error('[STATS ERROR]', err);
    return errorResponse(res, 'Gagal mengambil statistik dashboard: ' + err.message, 500);
  }
};

module.exports = {
  getDashboardStats,
};
