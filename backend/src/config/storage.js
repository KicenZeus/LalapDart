const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config();

const BASE_STORAGE_DIR = path.resolve(process.env.STORAGE_LOCAL_DIR || './uploads/lalapan-mobile-documents');

// Pastikan base directory ada
if (!fs.existsSync(BASE_STORAGE_DIR)) {
  fs.mkdirSync(BASE_STORAGE_DIR, { recursive: true });
}

/**
 * Storage Manager modular yang mengimplementasikan struktur MinIO
 * Key pattern: {registration_number}/{document_type}_{timestamp}.{ext}
 */
class StorageService {
  /**
   * Simpan file ke storage
   */
  async saveFile({ registrationNumber, documentType, originalName, buffer }) {
    const ext = path.extname(originalName) || '.jpg';
    const timestamp = Date.now();
    const sanitizedReg = registrationNumber.replace(/[^a-zA-Z0-9_-]/g, '_');
    const fileName = `${documentType}_${timestamp}${ext}`;
    const storageKey = `${sanitizedReg}/${fileName}`;

    const targetDir = path.join(BASE_STORAGE_DIR, sanitizedReg);
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    const fullPath = path.join(BASE_STORAGE_DIR, storageKey);
    await fs.promises.writeFile(fullPath, buffer);

    return {
      storageKey,
      fileName,
      fullPath,
      fileSize: buffer.length,
    };
  }

  /**
   * Dapatkan path fisik file dari storageKey
   */
  getFilePath(storageKey) {
    const fullPath = path.join(BASE_STORAGE_DIR, storageKey);
    if (!fs.existsSync(fullPath)) {
      return null;
    }
    return fullPath;
  }

  /**
   * Hapus file dari storage
   */
  async deleteFile(storageKey) {
    const fullPath = path.join(BASE_STORAGE_DIR, storageKey);
    if (fs.existsSync(fullPath)) {
      await fs.promises.unlink(fullPath);
      return true;
    }
    return false;
  }
}

module.exports = new StorageService();
