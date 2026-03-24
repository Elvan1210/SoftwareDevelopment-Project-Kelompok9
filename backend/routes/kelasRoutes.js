const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const ctrl = require('../controllers/kelasController');

router.get('/', verifyToken, ctrl.getAll);
router.get('/:id', verifyToken, ctrl.getById); // Added getById
router.post('/', verifyToken, ctrl.create);
router.put('/:id', verifyToken, ctrl.update);
router.delete('/:id', verifyToken, ctrl.remove);

module.exports = router;
