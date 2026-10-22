/**
 * Format standar response JSON sesuai PRD Bagian 9
 */
const successResponse = (res, data = null, message = 'Operasi berhasil', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    data,
    message,
  });
};

const errorResponse = (res, message = 'Terjadi kesalahan sistem', statusCode = 500, errors = null) => {
  return res.status(statusCode).json({
    success: false,
    message,
    ...(errors ? { errors } : {}),
  });
};

module.exports = {
  successResponse,
  errorResponse,
};
