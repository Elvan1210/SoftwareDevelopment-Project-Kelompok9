require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const db = require('./config/db');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ─── Middleware JWT Auth ────────────────────────────────────────────────────
const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Format: "Bearer <token>"
  if (!token) return res.status(401).json({ message: 'Akses ditolak. Token tidak ada.' });

  jwt.verify(token, process.env.JWT_SECRET || 'rahasia', (err, decoded) => {
    if (err) return res.status(403).json({ message: 'Token tidak valid atau sudah expired.' });
    req.user = decoded;
    next();
  });
};
// ───────────────────────────────────────────────────────────────────────────

app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: 'Email dan password wajib diisi' });

    const snapshot = await db.collection('users').where('email', '==', email).get();
    if (snapshot.empty) return res.status(401).json({ message: 'Email tidak terdaftar' });

    let userData, userId;
    snapshot.forEach(doc => { userId = doc.id; userData = doc.data(); });

    const isPasswordValid = await bcrypt.compare(password, userData.password);
    if (!isPasswordValid) return res.status(401).json({ message: 'Password salah' });

    const token = jwt.sign({ id: userId, role: userData.role, email: userData.email }, process.env.JWT_SECRET || 'rahasia', { expiresIn: '24h' });

    res.status(200).json({
      message: 'Login berhasil',
      token: token,
      user: { id: userId, nama: userData.nama, role: userData.role, email: userData.email, kelas: userData.kelas }
    });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

const generateCrudRoutes = (collectionName) => {
  app.get(`/api/${collectionName}`, verifyToken, async (req, res) => {
    try {
      const snapshot = await db.collection(collectionName).get();
      const data = [];
      snapshot.forEach(doc => data.push({ id: doc.id, ...doc.data() }));
      res.status(200).json(data);
    } catch (error) { res.status(500).json({ message: 'Error server', error: error.message }); }
  });

  app.post(`/api/${collectionName}`, verifyToken, async (req, res) => {
    try {
      const docRef = await db.collection(collectionName).add(req.body);
      res.status(201).json({ message: 'Data dibuat', id: docRef.id });
    } catch (error) { res.status(500).json({ message: 'Error server', error: error.message }); }
  });

  app.put(`/api/${collectionName}/:id`, verifyToken, async (req, res) => {
    try {
      await db.collection(collectionName).doc(req.params.id).update(req.body);
      res.status(200).json({ message: 'Data diupdate' });
    } catch (error) { res.status(500).json({ message: 'Error server', error: error.message }); }
  });

  app.delete(`/api/${collectionName}/:id`, verifyToken, async (req, res) => {
    try {
      await db.collection(collectionName).doc(req.params.id).delete();
      res.status(200).json({ message: 'Data dihapus' });
    } catch (error) { res.status(500).json({ message: 'Error server', error: error.message }); }
  });
};

generateCrudRoutes('kelas');
generateCrudRoutes('tugas');
generateCrudRoutes('nilai');
generateCrudRoutes('pengumuman');
generateCrudRoutes('pengumpulan');

app.get('/api/users', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = [];
    snapshot.forEach(doc => users.push({ id: doc.id, ...doc.data() }));
    res.status(200).json(users);
  } catch (error) { res.status(500).json({ message: 'Error server', error: error.message }); }
});

app.post('/api/users', verifyToken, async (req, res) => {
  try {
    const { nama, email, password, role, kelas } = req.body;
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const newUser = { nama, email, password: hashedPassword, role, kelas: kelas || '', waktu_daftar: new Date() };
    const docRef = await db.collection('users').add(newUser);
    res.status(201).json({ message: 'User dibuat', id: docRef.id });
  } catch (error) { res.status(500).json({ message: 'Error server', error: error.message }); }
});

app.put('/api/users/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, email, role, password, kelas } = req.body;
    const updateData = { nama, email, role, kelas };
    if (password && password.trim() !== '') {
      const salt = await bcrypt.genSalt(10);
      updateData.password = await bcrypt.hash(password, salt);
    }
    await db.collection('users').doc(id).update(updateData);
    res.status(200).json({ message: 'User diupdate' });
  } catch (error) { res.status(500).json({ message: 'Error server', error: error.message }); }
});

app.delete('/api/users/:id', verifyToken, async (req, res) => {
  try {
    await db.collection('users').doc(req.params.id).delete();
    res.status(200).json({ message: 'User dihapus' });
  } catch (error) { res.status(500).json({ message: 'Error server', error: error.message }); }
});

app.listen(port, () => {
  console.log(`Server Backend berjalan di http://localhost:${port}`);
});