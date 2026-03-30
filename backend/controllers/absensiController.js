const db = require('../config/db');

/**
 * Controller untuk Absensi.
 * Composite key: absensi/{kode_kelas}_{tanggal}
 * records: map { siswa_id: "hadir" | "izin" | "sakit" | "alpha" }
 */

const absensiController = {
  // GET /api/absensi?kode_kelas=...&tanggal=...  → single session
  // GET /api/absensi?kode_kelas=...              → all sessions for a class
  getAll: async (req, res) => {
    try {
      const { kode_kelas, tanggal } = req.query;

      if (!kode_kelas) {
        return res.status(400).json({ message: 'kode_kelas wajib diisi.' });
      }

      if (tanggal) {
        // Fetch single session
        const docId = `${kode_kelas}_${tanggal}`;
        const doc = await db.collection('absensi').doc(docId).get();
        if (!doc.exists) {
          return res.status(200).json(null);
        }
        return res.status(200).json({ id: doc.id, ...doc.data() });
      }

      // Fetch all sessions for a class
      const snapshot = await db.collection('absensi')
        .where('kode_kelas', '==', kode_kelas)
        .get();

      const data = [];
      snapshot.forEach(doc => data.push({ id: doc.id, ...doc.data() }));

      // Sort by tanggal descending (newest first)
      data.sort((a, b) => (b.tanggal || '').localeCompare(a.tanggal || ''));

      return res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/absensi  → upsert (create or overwrite) session
  // Body: { kode_kelas, tanggal, guru_id, records: { siswa_id: status, ... } }
  upsert: async (req, res) => {
    try {
      const { kode_kelas, tanggal, guru_id, records } = req.body;

      if (!kode_kelas || !tanggal) {
        return res.status(400).json({ message: 'kode_kelas dan tanggal wajib diisi.' });
      }

      const docId = `${kode_kelas}_${tanggal}`;
      const payload = {
        kode_kelas,
        tanggal,
        guru_id: guru_id || null,
        records: records || {},
        updated_at: new Date().toISOString(),
      };

      await db.collection('absensi').doc(docId).set(payload, { merge: false });

      res.status(200).json({ message: 'Absensi berhasil disimpan.', id: docId });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },
};

module.exports = absensiController;
