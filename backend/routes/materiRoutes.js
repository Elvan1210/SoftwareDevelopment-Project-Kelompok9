const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const { requireRole } = require('../middleware/rbac');
const createCrudController = require('../controllers/genericCrudController');
const { upload, uploadFile } = require('../controllers/uploadController'); //

const ctrl = createCrudController('materi');

// Endpoint untuk upload file materi
router.post('/upload', verifyToken, requireRole('Guru', 'Admin'), upload.single('file'), uploadFile); //

// Endpoint CRUD standar
router.get('/', verifyToken, ctrl.getAll);
router.post('/', verifyToken, requireRole('Guru', 'Admin'), ctrl.create);
router.put('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.update);
router.delete('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.remove);

module.exports = router;