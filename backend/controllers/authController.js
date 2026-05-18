const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');
const db = require('../config/db');

// ─── Gmail SMTP Transporter ──────────────────────────────────────────────────
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

// ─── Helper: generate 6-digit OTP ───────────────────────────────────────────
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// ─── POST /api/login ─────────────────────────────────────────────────────────
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: 'Email dan password wajib diisi' });

    const snapshot = await db.collection('users').where('email', '==', email).get();
    if (snapshot.empty) return res.status(401).json({ message: 'Email tidak terdaftar' });

    let userData, userId;
    snapshot.forEach(doc => { userId = doc.id; userData = doc.data(); });

    const isPasswordValid = await bcrypt.compare(password, userData.password);
    if (!isPasswordValid) return res.status(401).json({ message: 'Password salah' });
    const settings = require('../config/settings');
    const token = jwt.sign(
      { id: userId, role: userData.role, email: userData.email },
      settings.jwtSecret,
      { expiresIn: '24h' }
    );

    res.status(200).json({
      message: 'Login berhasil',
      token: token,
      user: { 
        id: userId, 
        nama: userData.nama, 
        role: userData.role, 
        email: userData.email, 
        kelas: userData.kelas,
        status: userData.status || 'Available' // <-- Tambahan status
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
};

// ─── POST /api/forgot-password ───────────────────────────────────────────────
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email wajib diisi' });

    const snapshot = await db.collection('users').where('email', '==', email).get();
    if (snapshot.empty) return res.status(404).json({ message: 'Email tidak terdaftar dalam sistem' });

    let userData;
    snapshot.forEach(doc => { userData = doc.data(); });

    const otp = generateOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); 

    const existingOtp = await db.collection('otpCodes').where('email', '==', email).get();
    
    // OTP Cooldown check
    let canSend = true;
    let timeRemaining = 0;
    const nowTime = new Date().getTime();
    existingOtp.forEach(doc => {
      const otpData = doc.data();
      if (otpData.createdAt) {
        const createdAt = new Date(otpData.createdAt).getTime();
        const diff = nowTime - createdAt;
        if (diff < 60 * 1000) { // 60 seconds cooldown
          canSend = false;
          timeRemaining = Math.ceil((60 * 1000 - diff) / 1000);
        }
      }
    });

    if (!canSend) {
      return res.status(429).json({ message: `Harap tunggu ${timeRemaining} detik sebelum meminta OTP baru` });
    }

    const deletePromises = [];
    existingOtp.forEach(doc => deletePromises.push(doc.ref.delete()));
    await Promise.all(deletePromises);

    await db.collection('otpCodes').add({
      email, code: otp, expiresAt: expiresAt.toISOString(), used: false, createdAt: new Date().toISOString(),
    });

    const mailOptions = {
      from: `"MyPSKD" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: 'Kode Verifikasi Reset Password — MyPSKD',
      html: `
        <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(7,88,100,0.10);">
          <div style="background: linear-gradient(135deg, #075864 0%, #76AFB8 100%); padding: 36px 32px 32px;">
            <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 8px;">
              <div style="background: rgba(255,255,255,0.2); border-radius: 10px; width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; font-size: 20px;">🎓</div>
              <span style="color: #ffffff; font-size: 20px; font-weight: 800; letter-spacing: -0.5px;">MyPSKD</span>
            </div>
            <h1 style="color: #ffffff; margin: 16px 0 0; font-size: 24px; font-weight: 700; letter-spacing: -0.5px;">Reset Kata Sandi</h1>
            <p style="color: rgba(255,255,255,0.8); margin: 8px 0 0; font-size: 14px;">Platform Manajemen Sekolah Digital</p>
          </div>
          <div style="padding: 32px;">
            <p style="color: #374151; font-size: 15px; margin: 0 0 8px;">Halo, <strong>${userData.nama || email}</strong>!</p>
            <p style="color: #6B7280; font-size: 14px; margin: 0 0 28px; line-height: 1.6;">Kami menerima permintaan untuk mereset kata sandi akun MyPSKD kamu. Gunakan kode verifikasi berikut untuk melanjutkan:</p>
            
            <div style="background: #F0F9FA; border: 2px dashed #075864; border-radius: 16px; padding: 28px; text-align: center; margin-bottom: 28px;">
              <p style="color: #6B7280; font-size: 12px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; margin: 0 0 12px;">KODE VERIFIKASI</p>
              <div style="letter-spacing: 16px; font-size: 42px; font-weight: 900; color: #075864; font-family: 'Courier New', monospace;">${otp}</div>
              <p style="color: #9CA3AF; font-size: 12px; margin: 16px 0 0;">⏱️ Berlaku selama <strong>10 menit</strong></p>
            </div>

            <div style="background: #FEF3C7; border-radius: 10px; padding: 14px 16px; margin-bottom: 24px;">
              <p style="color: #92400E; font-size: 13px; margin: 0;">⚠️ <strong>Jangan bagikan kode ini</strong> kepada siapapun, termasuk pihak yang mengaku dari MyPSKD.</p>
            </div>

            <p style="color: #9CA3AF; font-size: 12px; line-height: 1.6; margin: 0;">Jika kamu tidak meminta reset kata sandi, abaikan email ini. Akun kamu tetap aman.</p>
          </div>
          <div style="background: #F9FAFB; padding: 20px 32px; border-top: 1px solid #E5E7EB;">
            <p style="color: #9CA3AF; font-size: 11px; margin: 0; text-align: center;">© 2025 MyPSKD — EduAdmin Platform Manajemen Sekolah</p>
          </div>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    res.status(200).json({ message: 'Kode verifikasi telah dikirim ke email kamu' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengirim email', error: error.message });
  }
};

// ─── POST /api/verify-otp ────────────────────────────────────────────────────
exports.verifyOtp = async (req, res) => {
  try {
    const { email, code } = req.body;
    if (!email || !code) return res.status(400).json({ message: 'Email dan kode wajib diisi' });

    const snapshot = await db.collection('otpCodes')
      .where('email', '==', email)
      .where('code', '==', code)
      .get();

    if (snapshot.empty) return res.status(400).json({ message: 'Kode verifikasi tidak valid' });

    let otpData;
    snapshot.forEach(doc => { otpData = doc.data(); });

    if (otpData.used) return res.status(400).json({ message: 'Kode verifikasi sudah digunakan' });

    const now = new Date();
    const expiresAt = new Date(otpData.expiresAt);
    if (now > expiresAt) return res.status(400).json({ message: 'Kode verifikasi sudah kadaluarsa' });

    res.status(200).json({ message: 'Kode verifikasi valid', valid: true });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
};

// ─── POST /api/reset-password ────────────────────────────────────────────────
exports.resetPassword = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    if (!email || !code || !newPassword) {
      return res.status(400).json({ message: 'Email, kode, dan password baru wajib diisi' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password minimal 6 karakter' });
    }

    const otpSnapshot = await db.collection('otpCodes')
      .where('email', '==', email)
      .where('code', '==', code)
      .get();

    if (otpSnapshot.empty) return res.status(400).json({ message: 'Kode verifikasi tidak valid' });

    let otpDoc, otpData;
    otpSnapshot.forEach(doc => { otpDoc = doc; otpData = doc.data(); });

    if (otpData.used) return res.status(400).json({ message: 'Kode verifikasi sudah digunakan' });

    const now = new Date();
    const expiresAt = new Date(otpData.expiresAt);
    if (now > expiresAt) return res.status(400).json({ message: 'Kode verifikasi sudah kadaluarsa' });

    const userSnapshot = await db.collection('users').where('email', '==', email).get();
    if (userSnapshot.empty) return res.status(404).json({ message: 'User tidak ditemukan' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const updatePromises = [];
    userSnapshot.forEach(doc => {
      updatePromises.push(doc.ref.update({ password: hashedPassword }));
    });
    await Promise.all(updatePromises);

    await otpDoc.ref.delete();
    res.status(200).json({ message: 'Password berhasil diperbarui' });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
};