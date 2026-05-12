const router = require('express').Router();
const authController = require('../controllers/authController');

// POST /api/login — tidak memerlukan token
router.post('/login', authController.login);

// POST /api/forgot-password — kirim OTP ke email
router.post('/forgot-password', authController.forgotPassword);

// POST /api/verify-otp — verifikasi kode OTP
router.post('/verify-otp', authController.verifyOtp);

// POST /api/reset-password — reset password dengan OTP
router.post('/reset-password', authController.resetPassword);

module.exports = router;
