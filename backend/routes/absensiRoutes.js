const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const ctrl = require('../controllers/absensiController');

router.get('/', verifyToken, ctrl.getAll);
router.post('/', verifyToken, ctrl.upsert);

module.exports = router;
