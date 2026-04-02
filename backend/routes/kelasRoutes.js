const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const ctrl = require('../controllers/kelasController');

// Rute Spesifik/Custom (harus di atas rute /:id)
router.post('/join', verifyToken, ctrl.joinKelasWithCode);

// Rute untuk pending requests & approval
router.get('/:id/pending', verifyToken, ctrl.getPendingRequests);
router.post('/:id/accept', verifyToken, ctrl.acceptStudent);
router.post('/:id/reject', verifyToken, ctrl.rejectStudent);
router.post('/:id/accept-all', verifyToken, ctrl.acceptAllStudents);
router.put('/:id/auto-accept', verifyToken, ctrl.toggleAutoAccept);
router.get('/:id/members', verifyToken, ctrl.getMembers);

// Rute CRUD Utama
router.get('/', verifyToken, ctrl.getAll);
router.get('/:id', verifyToken, ctrl.getById);
router.post('/', verifyToken, ctrl.create);
router.put('/:id', verifyToken, ctrl.update);
router.delete('/:id', verifyToken, ctrl.remove);

module.exports = router;