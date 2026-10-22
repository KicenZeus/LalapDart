-- ==============================================================================
-- SEED DATA 29 FASILITAS KESEHATAN KABUPATEN MADIUN
-- 3 RSUD + 26 PUSKESMAS
-- ==============================================================================

INSERT INTO institutions (id, type, name, code, address, phone, email, is_active)
VALUES
  -- 3 RSUD
  ('inst-rsud-01', 'RSUD', 'RSUD Caruban Kabupaten Madiun', 'RSUD-CRB', 'Jl. Ahmad Yani No. 10, Caruban, Kab. Madiun', '0351-383115', 'rsud.caruban@madiunkab.go.id', true),
  ('inst-rsud-02', 'RSUD', 'RSUD Dolopo Kabupaten Madiun', 'RSUD-DLP', 'Jl. Raya Dolopo No. 117, Dolopo, Kab. Madiun', '0351-366050', 'rsud.dolopo@madiunkab.go.id', true),
  ('inst-rsud-03', 'RSUD', 'RSUD Dungus Kabupaten Madiun', 'RSUD-DNG', 'Jl. Raya Dungus, Wungu, Kab. Madiun', '0351-829100', 'rsud.dungus@madiunkab.go.id', true),

  -- 26 Puskesmas
  ('inst-pkm-01', 'PUSKESMAS', 'Puskesmas Balerejo', 'PKM-BLR', 'Jl. Raya Balerejo No. 45, Kec. Balerejo', '0351-383201', 'pkm.balerejo@madiunkab.go.id', true),
  ('inst-pkm-02', 'PUSKESMAS', 'Puskesmas Simo', 'PKM-SMO', 'Jl. Raya Simo, Kec. Balerejo', '0351-383202', 'pkm.simo@madiunkab.go.id', true),
  ('inst-pkm-03', 'PUSKESMAS', 'Puskesmas Dagangan', 'PKM-DGG', 'Jl. Raya Dagangan No. 12, Kec. Dagangan', '0351-366101', 'pkm.dagangan@madiunkab.go.id', true),
  ('inst-pkm-04', 'PUSKESMAS', 'Puskesmas Dolopo', 'PKM-DLP-KEC', 'Jl. Raya Dolopo No. 88, Kec. Dolopo', '0351-366102', 'pkm.dolopo@madiunkab.go.id', true),
  ('inst-pkm-05', 'PUSKESMAS', 'Puskesmas Candimulyo', 'PKM-CDM', 'Jl. Raya Candimulyo, Kec. Dolopo', '0351-366103', 'pkm.candimulyo@madiunkab.go.id', true),
  ('inst-pkm-06', 'PUSKESMAS', 'Puskesmas Geger', 'PKM-GGR', 'Jl. Raya Uteran No. 25, Kec. Geger', '0351-366201', 'pkm.geger@madiunkab.go.id', true),
  ('inst-pkm-07', 'PUSKESMAS', 'Puskesmas Kaibon', 'PKM-KBN', 'Jl. Raya Kaibon, Kec. Geger', '0351-366202', 'pkm.kaibon@madiunkab.go.id', true),
  ('inst-pkm-08', 'PUSKESMAS', 'Puskesmas Gemarang', 'PKM-GMR', 'Jl. Raya Gemarang No. 15, Kec. Gemarang', '0351-383301', 'pkm.gemarang@madiunkab.go.id', true),
  ('inst-pkm-09', 'PUSKESMAS', 'Puskesmas Jiwan', 'PKM-JWN', 'Jl. Raya Solo - Jiwan No. 50, Kec. Jiwan', '0351-464101', 'pkm.jiwan@madiunkab.go.id', true),
  ('inst-pkm-10', 'PUSKESMAS', 'Puskesmas Klagenserut', 'PKM-KGS', 'Jl. Raya Klagenserut, Kec. Jiwan', '0351-464102', 'pkm.klagenserut@madiunkab.go.id', true),
  ('inst-pkm-11', 'PUSKESMAS', 'Puskesmas Kare', 'PKM-KRE', 'Jl. Raya Kare No. 8, Kec. Kare', '0351-366301', 'pkm.kare@madiunkab.go.id', true),
  ('inst-pkm-12', 'PUSKESMAS', 'Puskesmas Kebonsari', 'PKM-KBS', 'Jl. Raya Kebonsari No. 18, Kec. Kebonsari', '0351-366401', 'pkm.kebonsari@madiunkab.go.id', true),
  ('inst-pkm-13', 'PUSKESMAS', 'Puskesmas Gantrung', 'PKM-GTG', 'Jl. Raya Gantrung, Kec. Kebonsari', '0351-366402', 'pkm.gantrung@madiunkab.go.id', true),
  ('inst-pkm-14', 'PUSKESMAS', 'Puskesmas Madiun', 'PKM-MDN', 'Jl. Raya Madiun No. 33, Kec. Madiun', '0351-464201', 'pkm.madiun@madiunkab.go.id', true),
  ('inst-pkm-15', 'PUSKESMAS', 'Puskesmas Dimong', 'PKM-DMG', 'Jl. Raya Dimong, Kec. Madiun', '0351-464202', 'pkm.dimong@madiunkab.go.id', true),
  ('inst-pkm-16', 'PUSKESMAS', 'Puskesmas Mejayan', 'PKM-MJY', 'Jl. Panglima Sudirman No. 22, Caruban, Kec. Mejayan', '0351-383401', 'pkm.mejayan@madiunkab.go.id', true),
  ('inst-pkm-17', 'PUSKESMAS', 'Puskesmas Klecorejo', 'PKM-KCR', 'Jl. Raya Klecorejo, Kec. Mejayan', '0351-383402', 'pkm.klecorejo@madiunkab.go.id', true),
  ('inst-pkm-18', 'PUSKESMAS', 'Puskesmas Bangunsari', 'PKM-BGS', 'Jl. Bangunsari No. 14, Kec. Mejayan', '0351-383403', 'pkm.bangunsari@madiunkab.go.id', true),
  ('inst-pkm-19', 'PUSKESMAS', 'Puskesmas Pilangkenceng', 'PKM-PKC', 'Jl. Raya Pilangkenceng No. 11, Kec. Pilangkenceng', '0351-383501', 'pkm.pilangkenceng@madiunkab.go.id', true),
  ('inst-pkm-20', 'PUSKESMAS', 'Puskesmas Krebet', 'PKM-KBT', 'Jl. Raya Krebet, Kec. Pilangkenceng', '0351-383502', 'pkm.krebet@madiunkab.go.id', true),
  ('inst-pkm-21', 'PUSKESMAS', 'Puskesmas Saradan', 'PKM-SRD', 'Jl. Raya Saradan No. 29, Kec. Saradan', '0351-383601', 'pkm.saradan@madiunkab.go.id', true),
  ('inst-pkm-22', 'PUSKESMAS', 'Puskesmas Pajaran', 'PKM-PJR', 'Jl. Raya Pajaran, Kec. Saradan', '0351-383602', 'pkm.pajaran@madiunkab.go.id', true),
  ('inst-pkm-23', 'PUSKESMAS', 'Puskesmas Sawahan', 'PKM-SWH', 'Jl. Raya Sawahan No. 5, Kec. Sawahan', '0351-464301', 'pkm.sawahan@madiunkab.go.id', true),
  ('inst-pkm-24', 'PUSKESMAS', 'Puskesmas Wonoasri', 'PKM-WNS', 'Jl. Raya Wonoasri No. 17, Kec. Wonoasri', '0351-383701', 'pkm.wonoasri@madiunkab.go.id', true),
  ('inst-pkm-25', 'PUSKESMAS', 'Puskesmas Wungu', 'PKM-WNG', 'Jl. Raya Mojopurno No. 30, Kec. Wungu', '0351-829201', 'pkm.wungu@madiunkab.go.id', true),
  ('inst-pkm-26', 'PUSKESMAS', 'Puskesmas Mojopurno', 'PKM-MJP', 'Jl. Raya Dungus - Mojopurno, Kec. Wungu', '0351-829202', 'pkm.mojopurno@madiunkab.go.id', true)
ON CONFLICT (code) DO NOTHING;

-- ==============================================================================
-- SEED INITIAL USERS
-- Password Default:
-- admin: Admin123!
-- verifikator: Dukcapil123!
-- bidan_caruban / bidan_dolopo / bidan_balerejo: Bidan123!
-- ==============================================================================

INSERT INTO users (id, username, password, plain_password, full_name, role, institution_id, institution_name, email, is_active)
VALUES
  -- 1. Super Admin
  (
    'usr-admin-01',
    'admin',
    crypt('Admin123!', gen_salt('bf', 10)),
    'Admin123!',
    'Administrator Disdukcapil Madiun',
    'ADMIN',
    NULL,
    'Disdukcapil Kabupaten Madiun',
    'admin.lalapan@madiunkab.go.id',
    true
  ),
  -- 2. Verifikator Disdukcapil
  (
    'usr-verif-01',
    'verifikator',
    crypt('Dukcapil123!', gen_salt('bf', 10)),
    'Dukcapil123!',
    'Siti Rahmawati (Verifikator Akta)',
    'OPERATOR_DUKCAPIL',
    NULL,
    'Bidang Pelayanan Pencatatan Sipil',
    'siti.verif@madiunkab.go.id',
    true
  ),
  -- 3. Operator Faskes: RSUD Caruban
  (
    'usr-op-01',
    'bidan_caruban',
    crypt('Bidan123!', gen_salt('bf', 10)),
    'Bidan123!',
    'Bidan Anisa Dewi, S.Tr.Keb',
    'OPERATOR_RS',
    'inst-rsud-01',
    'RSUD Caruban Kabupaten Madiun',
    'anisa.caruban@madiunkab.go.id',
    true
  ),
  -- 4. Operator Faskes: RSUD Dolopo
  (
    'usr-op-02',
    'bidan_dolopo',
    crypt('Bidan123!', gen_salt('bf', 10)),
    'Bidan123!',
    'Bidan Ratna Sari, Amd.Keb',
    'OPERATOR_RS',
    'inst-rsud-02',
    'RSUD Dolopo Kabupaten Madiun',
    'ratna.dolopo@madiunkab.go.id',
    true
  ),
  -- 5. Operator Faskes: Puskesmas Balerejo
  (
    'usr-op-03',
    'bidan_balerejo',
    crypt('Bidan123!', gen_salt('bf', 10)),
    'Bidan123!',
    'Bidan Nurul Hidayah, S.Tr.Keb',
    'OPERATOR_RS',
    'inst-pkm-01',
    'Puskesmas Balerejo',
    'nurul.balerejo@madiunkab.go.id',
    true
  )
ON CONFLICT (username) DO NOTHING;
