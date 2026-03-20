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

app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email dan password wajib diisi' });
    }

    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', email).get();

    if (snapshot.empty) {
      return res.status(401).json({ message: 'Email tidak terdaftar' });
    }

    let userData;
    let userId;
    snapshot.forEach(doc => {
      userId = doc.id;
      userData = doc.data();
    });

    const isPasswordValid = await bcrypt.compare(password, userData.password);

    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Password salah' });
    }

    const token = jwt.sign(
      { id: userId, role: userData.role, email: userData.email },
      process.env.JWT_SECRET || 'rahasia',
      { expiresIn: '24h' }
    );

    res.status(200).json({
      message: 'Login berhasil',
      token: token,
      user: {
        id: userId,
        nama: userData.nama,
        role: userData.role,
        email: userData.email
      }
    });

  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

app.get('/api/users', async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = [];
    snapshot.forEach(doc => {
      users.push({ id: doc.id, ...doc.data() });
    });
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { nama, email, password, role } = req.body;

    if (!nama || !email || !password || !role) {
      return res.status(400).json({ message: 'Data tidak lengkap' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = {
      nama: nama,
      email: email,
      password: hashedPassword,
      role: role,
      waktu_daftar: new Date()
    };

    const docRef = await db.collection('users').add(newUser);
    res.status(201).json({ message: 'User dibuat', id: docRef.id });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

app.put('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, email, role, password } = req.body;
    
    const updateData = { nama, email, role };

    if (password && password.trim() !== '') {
      const salt = await bcrypt.genSalt(10);
      updateData.password = await bcrypt.hash(password, salt);
    }

    await db.collection('users').doc(id).update(updateData);
    res.status(200).json({ message: 'User diupdate' });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

app.delete('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection('users').doc(id).delete();
    res.status(200).json({ message: 'User dihapus' });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server Backend berjalan di http://localhost:${port}`);
});