const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let serviceAccount;

// Coba baca dari Environment Variable (Untuk Vercel / Production)
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (err) {
    console.error('Gagal parse FIREBASE_SERVICE_ACCOUNT:', err.message);
  }
}

// Fallback: Baca dari file lokal jika tidak ada di Env (Untuk Localhost)
if (!serviceAccount) {
  const keyPath = path.join(__dirname, '..', 'firebase-key.json');
  if (fs.existsSync(keyPath)) {
    serviceAccount = require(keyPath);
  } else {
    console.error('CRITICAL: Firebase credentials tidak ditemukan! Pastikan FIREBASE_CREDENTIALS di-set di Vercel, atau firebase-key.json ada di lokal.');
  }
}

if (serviceAccount && !admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();
module.exports = db;