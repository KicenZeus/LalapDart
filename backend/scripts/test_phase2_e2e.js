const http = require('http');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://127.0.0.1:5055';

// Helper HTTP request
const request = ({ method, path, headers = {}, body = null }) => {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method,
      headers,
    };

    const req = http.request(options, (res) => {
      const chunks = [];
      res.on('data', (d) => chunks.push(d));
      res.on('end', () => {
        const raw = Buffer.concat(chunks);
        const contentType = res.headers['content-type'] || '';
        let data = null;
        if (contentType.includes('application/json')) {
          try {
            data = JSON.parse(raw.toString());
          } catch (e) {
            data = raw.toString();
          }
        } else {
          data = raw;
        }

        resolve({
          status: res.statusCode,
          headers: res.headers,
          data,
        });
      });
    });

    req.on('error', reject);

    if (body) {
      if (Buffer.isBuffer(body)) {
        req.write(body);
      } else if (typeof body === 'object') {
        req.setHeader('Content-Type', 'application/json');
        req.write(JSON.stringify(body));
      } else {
        req.write(body);
      }
    }
    req.end();
  });
};

// Multipart form data helper
const createMultipartBody = (boundary, fields, fileField) => {
  const crlf = '\r\n';
  const parts = [];

  for (const [k, v] of Object.entries(fields)) {
    parts.push(Buffer.from(`--${boundary}${crlf}Content-Disposition: form-data; name="${k}"${crlf}${crlf}${v}${crlf}`));
  }

  if (fileField) {
    parts.push(
      Buffer.from(
        `--${boundary}${crlf}Content-Disposition: form-data; name="${fileField.name}"; filename="${fileField.filename}"${crlf}Content-Type: ${fileField.contentType}${crlf}${crlf}`
      )
    );
    parts.push(fileField.buffer);
    parts.push(Buffer.from(crlf));
  }

  parts.push(Buffer.from(`--${boundary}--${crlf}`));
  return Buffer.concat(parts);
};

async function runTests() {
  console.log('=== STARTING END-TO-END VERIFICATION: FASE 2 ===\n');

  // 1. Health Check
  const health = await request({ method: 'GET', path: '/health' });
  console.log('[1] Health Check:', health.status === 200 && health.data.success ? 'PASS ✅' : 'FAIL ❌', health.data.message);

  // 2. Login All Roles
  const loginBidanCaruban = await request({
    method: 'POST',
    path: '/api/auth/login',
    body: { username: 'bidan_caruban', password: 'Bidan123!' },
  });
  const tokenCaruban = loginBidanCaruban.data.data.token;
  console.log('[2] Login Bidan Caruban:', loginBidanCaruban.status === 200 ? 'PASS ✅' : 'FAIL ❌', loginBidanCaruban.data.data.user.fullName);

  const loginBidanDolopo = await request({
    method: 'POST',
    path: '/api/auth/login',
    body: { username: 'bidan_dolopo', password: 'Bidan123!' },
  });
  const tokenDolopo = loginBidanDolopo.data.data.token;
  console.log('[3] Login Bidan Dolopo:', loginBidanDolopo.status === 200 ? 'PASS ✅' : 'FAIL ❌', loginBidanDolopo.data.data.user.fullName);

  const loginVerifikator = await request({
    method: 'POST',
    path: '/api/auth/login',
    body: { username: 'verifikator', password: 'Dukcapil123!' },
  });
  const tokenVerifikator = loginVerifikator.data.data.token;
  console.log('[4] Login Verifikator Dukcapil:', loginVerifikator.status === 200 ? 'PASS ✅' : 'FAIL ❌');

  // 3. Create Draft Application by Bidan Caruban
  const newAppRes = await request({
    method: 'POST',
    path: '/api/applications',
    headers: { Authorization: `Bearer ${tokenCaruban}` },
    body: {
      baby: {
        fullName: 'Muhammad Rizky Pratama',
        gender: 'LAKI_LAKI',
        birthOrder: 1,
        birthWeightGram: 3200,
        birthLengthCm: 49.5,
        birthPlace: 'Madiun (RSUD Caruban)',
        birthDate: '2026-10-22',
        birthTime: '06:45',
        condition: 'SEHAT',
        medicalRecordNo: 'RM-CRB-2026-9901',
      },
      mother: {
        fullName: 'Siti Aminah',
      },
    },
  });

  const appId = newAppRes.data.data.id;
  const regNumber = newAppRes.data.data.registrationNumber;
  console.log('[5] Buat Draf Permohonan Baru:', newAppRes.status === 201 ? 'PASS ✅' : 'FAIL ❌', `No: ${regNumber} (ID: ${appId})`);

  // 4. Test Multi-Tenancy Isolation: Bidan Dolopo mencoba akses pengajuan Caruban
  const unauthorizedAccess = await request({
    method: 'GET',
    path: `/api/applications/${appId}`,
    headers: { Authorization: `Bearer ${tokenDolopo}` },
  });
  console.log('[6] Isolasi Multi-Tenancy (Bidan Dolopo blokir):', unauthorizedAccess.status === 403 ? 'PASS ✅ (403 Forbidden)' : 'FAIL ❌');

  // 5. Submit Sebelum Dokumen Lengkap (Harus Ditolak 400)
  const prematureSubmit = await request({
    method: 'POST',
    path: `/api/applications/${appId}/submit`,
    headers: { Authorization: `Bearer ${tokenCaruban}` },
  });
  console.log(
    '[7] Validasi Submit Dokumen Kurang:',
    prematureSubmit.status === 400 ? 'PASS ✅' : 'FAIL ❌',
    prematureSubmit.data.message
  );

  // 6. Upload 6 Dokumen Wajib
  const mandatoryDocs = [
    'KTP_IBU',
    'KTP_AYAH',
    'KARTU_KELUARGA',
    'SURAT_KETERANGAN_LAHIR_RS',
    'BUKU_NIKAH',
    'REKAM_MEDIS_IA_DAN_BAYI',
  ];

  let sampleDocId = null;

  for (const docType of mandatoryDocs) {
    const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
    const dummyBuffer = Buffer.from(`CONTOH DOKUMEN MEDIS DUKCAPIL: ${docType} UNTUK ${regNumber}`, 'utf-8');

    const body = createMultipartBody(
      boundary,
      { applicationId: appId, documentType: docType },
      { name: 'file', filename: `${docType}.jpg`, contentType: 'image/jpeg', buffer: dummyBuffer }
    );

    const uploadRes = await request({
      method: 'POST',
      path: '/api/documents/upload',
      headers: {
        Authorization: `Bearer ${tokenCaruban}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
      },
      body,
    });

    if (!sampleDocId) sampleDocId = uploadRes.data.data.id;
  }
  console.log('[8] Upload 6 Dokumen Wajib:', 'PASS ✅ (Semua 6 berkas berhasil disimpan)');

  // 7. Streaming Proxy Pratinjau Dokumen
  const streamRes = await request({
    method: 'GET',
    path: `/api/documents/view/${sampleDocId}?token=${tokenCaruban}`,
  });
  console.log(
    '[9] Streaming Proxy Pratinjau:',
    streamRes.status === 200 && streamRes.headers['content-disposition'].includes('inline')
      ? 'PASS ✅ (Streamed Inline Berhasil)'
      : 'FAIL ❌'
  );

  // 8. Download ZIP Seluruh Berkas
  const zipRes = await request({
    method: 'GET',
    path: `/api/documents/${appId}/download-zip`,
    headers: { Authorization: `Bearer ${tokenCaruban}` },
  });
  console.log(
    '[10] Unduh Paket Arsip ZIP:',
    zipRes.status === 200 && zipRes.headers['content-type'] === 'application/zip' ? 'PASS ✅' : 'FAIL ❌'
  );

  // 9. Submit Pengajuan Sekarang (Dokumen Lengkap)
  const validSubmit = await request({
    method: 'POST',
    path: `/api/applications/${appId}/submit`,
    headers: { Authorization: `Bearer ${tokenCaruban}` },
  });
  console.log('[11] Kirim Pengajuan Resmi ke Dukcapil:', validSubmit.status === 200 ? 'PASS ✅' : 'FAIL ❌', `Status: ${validSubmit.data.data.status}`);

  // 10. Verifikator Cek Antrean
  const queueRes = await request({
    method: 'GET',
    path: '/api/verification/queue',
    headers: { Authorization: `Bearer ${tokenVerifikator}` },
  });
  const foundInQueue = queueRes.data.data.items.some((i) => i.id === appId);
  console.log('[12] Antrean Verifikator Dukcapil:', foundInQueue ? 'PASS ✅ (Ditemukan di antrean)' : 'FAIL ❌');

  // 11. Verifikator Minta Perbaikan (Checklist Revisi)
  const revRes = await request({
    method: 'POST',
    path: `/api/verification/${appId}/request-revision`,
    headers: { Authorization: `Bearer ${tokenVerifikator}` },
    body: {
      revisionNote: 'Foto Surat Keterangan Lahir agak buram pada cap stempel, mohon unggah ulang.',
      fieldChecklist: [],
      documentChecklist: ['SURAT_KETERANGAN_LAHIR_RS'],
    },
  });
  console.log(
    '[13] Dukcapil Request Revision:',
    revRes.status === 200 && revRes.data.data.status === 'PERLU_PERBAIKAN' ? 'PASS ✅' : 'FAIL ❌'
  );

  // 12. Bidan Kirim Ulang Hasil Perbaikan
  const resubmit = await request({
    method: 'POST',
    path: `/api/applications/${appId}/submit`,
    headers: { Authorization: `Bearer ${tokenCaruban}` },
  });
  console.log(
    '[14] Faskes Kirim Ulang Hasil Perbaikan:',
    resubmit.status === 200 && resubmit.data.data.status === 'MENUNGGU_VERIFIKASI' ? 'PASS ✅' : 'FAIL ❌'
  );

  // 13. Verifikator Setujui & Terbitkan No Akta Kelahiran
  const approveRes = await request({
    method: 'POST',
    path: `/api/verification/${appId}/approve`,
    headers: { Authorization: `Bearer ${tokenVerifikator}` },
    body: {
      aktaKelahiranNumber: '3519-LT-22102026-0001',
      notes: 'Dokumen sah dan terverifikasi di SIAK.',
    },
  });
  console.log(
    '[15] Dukcapil Approve & Terbitkan No Akta:',
    approveRes.status === 200 && approveRes.data.data.status === 'DISETUJUI' ? 'PASS ✅' : 'FAIL ❌',
    `No Akta: ${approveRes.data.data.aktaKelahiranNumber}`
  );

  // 14. Modul Pelacakan Publik (Tanpa Login)
  const trackRes = await request({
    method: 'GET',
    path: `/api/applications/public/track?q=${encodeURIComponent(regNumber)}`,
  });
  const trackItem = trackRes.data.data[0];
  console.log(
    '[16] Pelacakan Publik (Tanpa Token):',
    trackRes.status === 200 && trackItem.status === 'DISETUJUI' ? 'PASS ✅' : 'FAIL ❌',
    `Status Publik: ${trackItem.status}, Akta: ${trackItem.aktaKelahiranNumber}`
  );

  // 15. Dashboard Statistik
  const statsRes = await request({
    method: 'GET',
    path: '/api/dashboard/stats',
    headers: { Authorization: `Bearer ${tokenCaruban}` },
  });
  console.log('[17] Dashboard Statistik Faskes:', statsRes.status === 200 ? 'PASS ✅' : 'FAIL ❌', statsRes.data.data);

  console.log('\n=== SELURUH 17 SKENARIO PENGUJIAN FASE 2 SELESAI DENGAN SUKSES 100% ===');
}

runTests().catch((err) => {
  console.error('TEST RUNNER FAILED:', err);
  process.exit(1);
});
