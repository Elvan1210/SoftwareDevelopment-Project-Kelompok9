const db = require('../config/db');

/**
 * Controller khusus untuk entitas 'Kelas'
 * Menangani logika relasional Guru & Siswa mirip Microsoft Teams.
 */
const kelasController = {
  // GET /api/kelas (dengan filter guru_id atau siswa_id)
  getAll: async (req, res) => {
    try {
      const { guru_id, siswa_id } = req.query;
      let queryRef = db.collection('kelas');

      if (guru_id) {
        queryRef = queryRef.where('guru_id', '==', guru_id);
      } else if (siswa_id) {
        queryRef = queryRef.where('siswa_ids', 'array-contains', siswa_id);
      }

      const snapshot = await queryRef.get();
      const data = [];
      snapshot.forEach(doc => data.push({ id: doc.id, ...doc.data() }));
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/kelas
  create: async (req, res) => {
    try {
      // Body example: { nama_kelas, kode_kelas, mapel, guru_id, guru_nama, siswa_ids: [], warna_card }
      const docRef = await db.collection('kelas').add(req.body);
      res.status(201).json({ message: 'Kelas berhasil dibuat', id: docRef.id });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // PUT /api/kelas/:id
  update: async (req, res) => {
    try {
      await db.collection('kelas').doc(req.params.id).update(req.body);
      res.status(200).json({ message: 'Kelas berhasil diperbarui' });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // DELETE /api/kelas/:id
  remove: async (req, res) => {
    try {
      await db.collection('kelas').doc(req.params.id).delete();
      res.status(200).json({ message: 'Kelas berhasil dihapus' });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // GET /api/kelas/:id
  getById: async (req, res) => {
    try {
      const doc = await db.collection('kelas').doc(req.params.id).get();
      if (!doc.exists) return res.status(404).json({ message: 'Kelas tidak ditemukan' });
      res.status(200).json({ id: doc.id, ...doc.data() });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  }
};

module.exports = kelasController;
