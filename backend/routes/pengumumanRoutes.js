const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const { requireRole } = require('../middleware/rbac');
const createCrudController = require('../controllers/genericCrudController');

const ctrl = createCrudController('pengumuman');

// GET — semua role yang sudah login bisa membaca pengumuman
router.get('/', verifyToken, ctrl.getAll);

// POST/PUT/DELETE — hanya Guru dan Admin yang boleh mengelola pengumuman
router.post('/', verifyToken, requireRole('Guru', 'Admin'), ctrl.create);
router.put('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.update);
router.delete('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.remove);

module.exports = router;
