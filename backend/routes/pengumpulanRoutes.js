const express = require('express');
const router = express.Router();

// 1. Import Middleware & Controllers
const verifyToken = require('../middleware/auth');
const createCrudController = require('../controllers/genericCrudController');
const { upload, uploadFile } = require('../controllers/uploadController');

// 2. Inisialisasi CRUD controller untuk collection 'pengumpulan'
const ctrl = createCrudController('pengumpulan');


// Route Khusus Upload (Wajib diletakkan di atas route CRUD biasa)
// Tips Tech Lead: Saya tambahkan verifyToken di sini agar tidak ada hacker
// yang iseng upload file ke Cloudinary kita secara sembarangan.
router.post('/upload', verifyToken, upload.single('file'), uploadFile);

// Route CRUD Standar
router.get('/', verifyToken, ctrl.getAll);
router.post('/', verifyToken, ctrl.create);
router.put('/:id', verifyToken, ctrl.update);
router.delete('/:id', verifyToken, ctrl.remove);

module.exports = router;