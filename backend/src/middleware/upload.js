const multer = require('multer');

// Gunakan memory storage agar buffer berkas bisa langsung disalurkan ke StorageService
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf',
  ];

  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Format berkas tidak didukung. Harap unggah berkas PDF atau Gambar (JPG, PNG, WEBP).'), false);
  }
};

const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // Maksimal 10 MB per berkas
  },
  fileFilter,
});

module.exports = upload;
