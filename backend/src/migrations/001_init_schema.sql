-- Extension UUID & Kriptografi
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. INSTITUTIONS
CREATE TABLE IF NOT EXISTS institutions (
  id VARCHAR(64) PRIMARY KEY,
  type VARCHAR(30) NOT NULL DEFAULT 'RS',
  name VARCHAR(200) NOT NULL,
  code VARCHAR(50) NOT NULL UNIQUE,
  address TEXT NOT NULL,
  head_of_service VARCHAR(150),
  phone VARCHAR(50),
  email VARCHAR(100),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. USERS
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(64) PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  plain_password VARCHAR(255),
  full_name VARCHAR(150) NOT NULL,
  role VARCHAR(50) NOT NULL, -- 'OPERATOR_RS', 'OPERATOR_DUKCAPIL', 'ADMIN'
  institution_id VARCHAR(64) REFERENCES institutions(id) ON DELETE SET NULL,
  institution_name VARCHAR(200),
  nip VARCHAR(50),
  email VARCHAR(100),
  phone VARCHAR(50),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. APPLICATIONS
CREATE TABLE IF NOT EXISTS applications (
  id VARCHAR(64) PRIMARY KEY,
  pgj_number VARCHAR(64) UNIQUE,
  registration_number VARCHAR(64),
  status VARCHAR(50) NOT NULL DEFAULT 'DRAFT', -- DRAFT, MENUNGGU_VERIFIKASI, PERLU_PERBAIKAN, DISETUJUI, DITOLAK
  operator_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  verifikator_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
  institution_id VARCHAR(64) REFERENCES institutions(id) ON DELETE SET NULL,
  institution_name VARCHAR(200),
  submitted_at TIMESTAMPTZ,
  verified_at TIMESTAMPTZ,
  last_revision_note TEXT,
  last_reject_note TEXT,
  revision_count INTEGER NOT NULL DEFAULT 0,
  akta_kelahiran_number VARCHAR(100),
  notes JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. BABY
CREATE TABLE IF NOT EXISTS baby (
  id VARCHAR(64) PRIMARY KEY,
  application_id VARCHAR(64) NOT NULL UNIQUE REFERENCES applications(id) ON DELETE CASCADE,
  full_name VARCHAR(150) NOT NULL,
  gender VARCHAR(20) NOT NULL, -- 'LAKI_LAKI', 'PEREMPUAN'
  birth_order INTEGER NOT NULL DEFAULT 1,
  birth_weight_gram INTEGER,
  birth_length_cm DECIMAL(5,1),
  birth_place VARCHAR(200) NOT NULL,
  birth_date DATE NOT NULL,
  birth_time VARCHAR(20) NOT NULL,
  condition VARCHAR(50) NOT NULL DEFAULT 'SEHAT',
  medical_record_no VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. MOTHER
CREATE TABLE IF NOT EXISTS mother (
  id VARCHAR(64) PRIMARY KEY,
  application_id VARCHAR(64) NOT NULL UNIQUE REFERENCES applications(id) ON DELETE CASCADE,
  full_name VARCHAR(150) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. APPLICATION_DOCUMENTS
CREATE TABLE IF NOT EXISTS application_documents (
  id VARCHAR(64) PRIMARY KEY,
  application_id VARCHAR(64) NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  document_type VARCHAR(50) NOT NULL, -- KTP_IBU, KTP_AYAH, KARTU_KELUARGA, SURAT_KETERANGAN_LAHIR_RS, BUKU_NIKAH, REKAM_MEDIS_IA_DAN_BAYI
  file_name VARCHAR(255) NOT NULL,
  original_file_name VARCHAR(255),
  file_url TEXT,
  storage_key VARCHAR(255),
  file_size BIGINT,
  mime_type VARCHAR(100),
  uploader_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(application_id, document_type)
);

-- 7. ACTIVITY_LOGS (Audit Trail)
CREATE TABLE IF NOT EXISTS activity_logs (
  id VARCHAR(64) PRIMARY KEY,
  application_id VARCHAR(64) REFERENCES applications(id) ON DELETE CASCADE,
  user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
  user_role VARCHAR(50),
  user_full_name VARCHAR(150),
  event_type VARCHAR(50) NOT NULL,
  action VARCHAR(50),
  old_status VARCHAR(50),
  new_status VARCHAR(50),
  summary TEXT,
  notes TEXT,
  metadata_json JSONB,
  ip_address VARCHAR(50),
  user_agent TEXT,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_institution_id ON users(institution_id);
CREATE INDEX IF NOT EXISTS idx_applications_operator_id ON applications(operator_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_pgj_number ON applications(pgj_number);
CREATE INDEX IF NOT EXISTS idx_documents_app_id ON application_documents(application_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_app_id ON activity_logs(application_id);
