const db = require('../config/db');

/**
 * Controller khusus untuk entitas 'Kelas'
 * Menangani logika relasional Guru & Siswa mirip Microsoft Teams.
 */

// Generate kode kelas unik 7 karakter (huruf besar + angka), mirip Google Classroom
const generateKodeKelas = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return Array.from({ length: 7 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
};

// Tentukan tahun ajaran otomatis: Juli-Des = tahun ini/tahun depan, Jan-Jun = tahun lalu/tahun ini
const getCurrentTahunAjaran = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1; // 1-12
  return month >= 7 ? `${year}/${year + 1}` : `${year - 1}/${year}`;
};

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
      const body = { ...req.body };
      // Auto-generate kode_kelas jika tidak disediakan atau kosong
      if (!body.kode_kelas || body.kode_kelas.trim() === '') {
        body.kode_kelas = generateKodeKelas();
      }
      // Auto-set tahun_ajaran berdasarkan kalender sekolah jika tidak disediakan
      if (!body.tahun_ajaran || body.tahun_ajaran.trim() === '') {
        body.tahun_ajaran = getCurrentTahunAjaran();
      }
      const docRef = await db.collection('kelas').add(body);
      res.status(201).json({ message: 'Kelas berhasil dibuat', id: docRef.id, kode_kelas: body.kode_kelas, tahun_ajaran: body.tahun_ajaran });
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
