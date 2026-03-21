const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const db = require('../config/db');

// POST /api/login
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

    const token = jwt.sign(
      { id: userId, role: userData.role, email: userData.email },
      process.env.JWT_SECRET || 'rahasia',
      { expiresIn: '24h' }
    );

    res.status(200).json({
      message: 'Login berhasil',
      token: token,
      user: { id: userId, nama: userData.nama, role: userData.role, email: userData.email, kelas: userData.kelas }
    });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
};
