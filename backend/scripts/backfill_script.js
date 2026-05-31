const admin = require('firebase-admin');

// Initialize Firebase Admin (assuming default env vars or simple init, let's just require db.js)
const path = require('path');
const db = require(path.join(__dirname, '../config/db.js'));

const generateAccessCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 8; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

async function runBackfill() {
  try {
    const snapshot = await db.collection('kelas').get();
    let updatedCount = 0;

    const batch = db.batch();
    snapshot.forEach(doc => {
      const data = doc.data();
      if (!data.kode_akses) {
        const docRef = db.collection('kelas').doc(doc.id);
        const newCode = generateAccessCode();
        batch.update(docRef, { kode_akses: newCode });
        console.log(`Assigned code ${newCode} to class ${doc.id}`);
        updatedCount++;
      }
    });

    if (updatedCount > 0) {
      await batch.commit();
      console.log(`Successfully generated access codes for ${updatedCount} classes.`);
    } else {
      console.log('No classes needed backfilling.');
    }
  } catch (error) {
    console.error('Error backfilling codes:', error.message);
  } finally {
    process.exit(0);
  }
}

runBackfill();
