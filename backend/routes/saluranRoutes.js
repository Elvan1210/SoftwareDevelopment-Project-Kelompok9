const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const { requireRole } = require('../middleware/rbac');
const createCrudController = require('../controllers/genericCrudController');

const ctrl = createCrudController('saluran');

/**
 * Saluran Diskusi — Chat per kelas (mirip channel di Microsoft Teams).
 *
 * Schema dokumen Firestore 'saluran':
 * {
 *   kelas_id:      string,  // ID kelas Firestore
 *   pengirim_id:   string,  // UID user pengirim
 *   pengirim_nama: string,  // Nama tampil pengirim
 *   role:          string,  // 'Guru' | 'Siswa' | 'Admin'
 *   pesan:         string,  // Isi pesan
 *   waktu:         string,  // ISO8601 timestamp
 * }
 *
 * GET dengan filter ?kelas_id=xxx memanfaatkan genericCrudController.getAll
 * yang sudah mendukung where clause dinamis.
 */

// GET — semua role yang login bisa membaca pesan di saluran
router.get('/', verifyToken, ctrl.getAll);

// POST — semua role yang login bisa mengirim pesan (Guru, Siswa, Admin)
router.post('/', verifyToken, ctrl.create);

// PUT — hanya Guru dan Admin yang bisa mengedit/menyemat pesan
router.put('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.update);

// DELETE — hanya Guru dan Admin yang bisa menghapus pesan
router.delete('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.remove);

module.exports = router;
