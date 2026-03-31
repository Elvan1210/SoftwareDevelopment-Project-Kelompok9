const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const { requireRole } = require('../middleware/rbac');
const userController = require('../controllers/userController');

// Semua operasi user management hanya untuk Admin
router.get('/', verifyToken, requireRole('Admin'), userController.getAll);
router.post('/', verifyToken, requireRole('Admin'), userController.create);
router.put('/:id', verifyToken, requireRole('Admin'), userController.update);
router.delete('/:id', verifyToken, requireRole('Admin'), userController.remove);

module.exports = router;
