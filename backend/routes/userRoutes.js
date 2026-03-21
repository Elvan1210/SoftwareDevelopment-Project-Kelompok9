const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const userController = require('../controllers/userController');

router.get('/', verifyToken, userController.getAll);
router.post('/', verifyToken, userController.create);
router.put('/:id', verifyToken, userController.update);
router.delete('/:id', verifyToken, userController.remove);

module.exports = router;
