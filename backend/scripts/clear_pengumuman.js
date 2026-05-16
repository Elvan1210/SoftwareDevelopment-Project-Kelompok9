/**
 * Script: hapus semua dokumen di collection 'pengumuman' dari Firestore
 * Jalankan: node scripts/clear_pengumuman.js
 */
require('dotenv').config();
const db = require('../config/db');

async function clearPengumuman() {
  const snapshot = await db.collection('pengumuman').get();
  if (snapshot.empty) {
    console.log('Collection pengumuman sudah kosong.');
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();

  console.log(`✅ Berhasil hapus ${snapshot.size} dokumen pengumuman.`);
  process.exit(0);
}

clearPengumuman().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});
