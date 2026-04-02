const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const { requireRole } = require('../middleware/rbac');
const db = require('../config/db');
const createCrudController = require('../controllers/genericCrudController');

const ctrl = createCrudController('notifikasi');

/**
 * GET /api/notifikasi
 *
 * Mengembalikan notifikasi yang relevan untuk user yang sedang login.
 * Logika filter (sama dengan yang ada di frontend notification_bell.dart):
 *  1. Jika notifikasi punya `target_user_id`, hanya user tersebut yang menerima.
 *  2. Jika tidak, cocokkan `target_role` (null/'Semua'/role user) DAN `target_kelas`.
 *
 * Dengan filter di backend, frontend tidak perlu filter client-side lagi.
 */
router.get('/', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id || req.user.uid;
    const userRole = req.user.role;
    const userKelas = req.user.kelas || null;

    const snapshot = await db.collection('notifikasi').orderBy('waktu', 'desc').limit(100).get();
    const allNotifs = [];
    snapshot.forEach(doc => allNotifs.push({ id: doc.id, ...doc.data() }));

    // Filter di sisi server sesuai logika targeting
    const myNotifs = allNotifs.filter(n => {
      // 1. Target user spesifik
      if (n.target_user_id != null) {
        return n.target_user_id === userId;
      }
      // 2. Filter berdasarkan role dan kelas
      const roleMatch = !n.target_role || n.target_role === 'Semua' || n.target_role === userRole;
      const kelasMatch = !n.target_kelas || n.target_kelas === userKelas;
      if (!(roleMatch && kelasMatch)) return false;

      // 3. Filter jika dihapus oleh user ini (Soft delete)
      if (n.dihapus_oleh && n.dihapus_oleh.includes(userId)) return false;
      return true;
    });

    res.status(200).json(myNotifs);
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

// PUT /api/notifikasi/:id/hide — Sembunyikan notifikasi tertentu (Trash icon)
router.put('/:id/hide', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id || req.user.uid;
    const docRef = db.collection('notifikasi').doc(req.params.id);
    const doc = await docRef.get();
    if (!doc.exists) return res.status(404).json({ message: 'Notifikasi tidak ditemukan' });

    let dihapus = doc.data().dihapus_oleh || [];
    if (!dihapus.includes(userId)) {
      dihapus.push(userId);
      await docRef.update({ dihapus_oleh: dihapus });
    }
    res.status(200).json({ message: 'Notifikasi dihapus (disembunyikan) untuk Anda' });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

// PUT /api/notifikasi/user/hide-all — Sembunyikan semua notifikasi yang ada
router.put('/user/hide-all', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id || req.user.uid;
    const userRole = req.user.role;
    const userKelas = req.user.kelas || null;

    const snapshot = await db.collection('notifikasi').get();
    
    // Gunakan batch untuk efisiensi jika notifikasinya banyak
    const batch = db.batch();
    
    snapshot.forEach(doc => {
      const n = doc.data();
      // Hanya sembunyikan yang targetnya sesuai dengan user
      let isTarget = false;
      if (n.target_user_id != null) {
        if (n.target_user_id === userId) isTarget = true;
      } else {
        const roleMatch = !n.target_role || n.target_role === 'Semua' || n.target_role === userRole;
        const kelasMatch = !n.target_kelas || n.target_kelas === userKelas;
        if (roleMatch && kelasMatch) isTarget = true;
      }

      if (isTarget) {
        let dihapus = n.dihapus_oleh || [];
        if (!dihapus.includes(userId)) {
          dihapus.push(userId);
          batch.update(doc.ref, { dihapus_oleh: dihapus });
        }
      }
    });

    await batch.commit();
    res.status(200).json({ message: 'Semua notifikasi dihapus (disembunyikan) untuk Anda' });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

// POST — Admin dan Guru bisa mengirim notifikasi
router.post('/', verifyToken, requireRole('Admin', 'Guru'), ctrl.create);

// PUT — untuk mark as read, semua role boleh (user update notif miliknya sendiri)
router.put('/:id', verifyToken, ctrl.update);

// DELETE — hanya Admin
router.delete('/:id', verifyToken, requireRole('Admin'), ctrl.remove);

module.exports = router;
