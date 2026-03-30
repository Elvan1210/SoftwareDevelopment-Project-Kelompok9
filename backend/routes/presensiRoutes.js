const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const createCrudController = require('../controllers/genericCrudController');

const ctrl = createCrudController('presensi');

router.get('/', verifyToken, ctrl.getAll);
router.post('/', verifyToken, ctrl.create);
router.put('/:id', verifyToken, ctrl.update);
router.delete('/:id', verifyToken, ctrl.remove);

module.exports = router;
