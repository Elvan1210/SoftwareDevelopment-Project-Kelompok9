const admin = require('firebase-admin');
// Titik dua (../) artinya keluar dari folder 'config' untuk mencari file kunci
const serviceAccount = require('../firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
console.log('Koneksi ke Firestore Database MyPSKD berhasil! ✅');

module.exports = db;