const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const { requireRole } = require('../middleware/rbac');
const createCrudController = require('../controllers/genericCrudController');

const ctrl = createCrudController('channels');

/**
 * Endpoint untuk manajemen Channels di dalam Saluran Teams (Mendukung Multi-Channel)
 *
 * Schema dokumen Firestore 'channels':
 * {
 *   kelas_id:      string,  // ID referensi kelas
 *   nama_channel:  string,  // Nama Channel (misal: "General", "Praktikum 01")
 *   created_by_id: string,  // Orang yang membuat
 *   waktu:         string,  // Waktu dibuat
 * }
 */

// GET — semua role bisa membaca channel, filter via ?kelas_id=
router.get('/', verifyToken, ctrl.getAll);

// POST — cuma Guru dan Admin yang boleh men-setup ruang channel
router.post('/', verifyToken, requireRole('Guru', 'Admin'), ctrl.create);

// PUT & DELETE untuk modifikasi lanjutan jika guru mau menghapus/re-name
router.put('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.update);
router.delete('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.remove);

module.exports = router;
