const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// ── Gunakan global caching agar tidak re-init di setiap Vercel serverless invocation ──
// Vercel re-uses warm instances, tapi cold start bisa terjadi kapan saja.
// Simpan di global scope agar persist selama instance hidup.
if (!global._firebaseAdminInitialized) {
  let serviceAccount;

  // Prioritaskan env var (Vercel Production)
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (err) {
      console.error('Gagal parse FIREBASE_SERVICE_ACCOUNT:', err.message);
    }
  }

  // Fallback: baca dari file lokal (localhost dev)
  if (!serviceAccount) {
    const keyPath = path.join(__dirname, '..', 'firebase-key.json');
    if (fs.existsSync(keyPath)) {
      serviceAccount = require(keyPath);
    } else {
      console.error('CRITICAL: Firebase credentials tidak ditemukan! Set FIREBASE_SERVICE_ACCOUNT di Vercel env vars.');
    }
  }

  if (serviceAccount && !admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }

  global._firebaseAdminInitialized = true;
}

const db = admin.firestore();

// Optimasi Firestore: aktifkan cache lokal untuk kurangi round-trip
// (hanya efektif di lingkungan non-serverless, tapi tidak merusak di serverless)
module.exports = db;