const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const { requireRole } = require('../middleware/rbac');
const createCrudController = require('../controllers/genericCrudController');
const db = require('../config/db');

const ctrl = createCrudController('tugas');

router.get('/', verifyToken, ctrl.getAll);
// GET by ID
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const doc = await db.collection('tugas').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ message: 'Tugas tidak ditemukan' });
    res.json({ id: doc.id, ...doc.data() });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

router.post('/', verifyToken, requireRole('Guru', 'Admin'), async (req, res) => {
  try {
    const docRef = await db.collection('tugas').add(req.body);
    const { channel_id, kelas_id, judul, guru_id, deskripsi, deadline, waktu } = req.body;

    if (channel_id && kelas_id) {
      const pesanChannel = {
        kelas_id,
        channel_id: channel_id === 'general' ? 'general' : channel_id,
        pengirim_id: guru_id || 'system',
        pengirim_nama: req.body.guru_nama || 'Guru',
        role: 'Guru',
        pesan: judul,
        tipe: 'tugas',
        tugas_id: docRef.id,
        judul_tugas: judul,
        deadline_tugas: deadline || null,
        waktu: waktu || new Date().toISOString(),
      };

      await db.collection('saluran').add(pesanChannel);

      // Notifikasi ke siswa
      const kelasDoc = await db.collection('kelas').doc(kelas_id).get();
      console.log('kelasDoc exists:', kelasDoc.exists);
      if (kelasDoc.exists) {
        const siswaIds = kelasDoc.data().siswa_ids || [];
        console.log('siswaIds:', siswaIds);
        if (siswaIds.length > 0) {
          const batch = db.batch();
          siswaIds.forEach(siswaId => {
            const notifRef = db.collection('notifikasi').doc();
            batch.set(notifRef, {
              judul: `Tugas Baru: ${judul}`,
              pesan: deskripsi || 'Ada tugas baru untuk kamu',
              target_id: siswaId,
              target_role: 'Siswa',
              is_read: false,
              waktu: new Date().toISOString(),
            });
          });
          await batch.commit();
          console.log('Notifikasi terkirim ke', siswaIds.length, 'siswa');
        }
      }
    }

    res.status(201).json({ message: 'Tugas dibuat', id: docRef.id });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

router.put('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.update);
router.delete('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.remove);


module.exports = router;