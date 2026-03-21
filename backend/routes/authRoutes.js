const router = require('express').Router();
const authController = require('../controllers/authController');

// POST /api/login — tidak memerlukan token
router.post('/login', authController.login);

module.exports = router;
