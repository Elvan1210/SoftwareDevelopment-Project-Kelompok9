require('dotenv').config(); // Wajib paling atas untuk membaca .env
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const db = require('./config/db'); // Memanggil koneksi Firestore

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ==========================================
// RUTE DASAR
// ==========================================
app.get('/', (req, res) => {
  res.send('Selamat datang di API MyPSKD! Server berjalan normal. 🚀');
});

app.get('/test-tambah', async (req, res) => {
  try {
    const userRef = db.collection('users').doc('test_01');
    await userRef.set({
      nama: 'Elvan Mariano',
      role: 'Siswa',
      waktu_daftar: new Date()
    });
    res.send('Sukses! Data test berhasil masuk ke Firestore! 🚀');
  } catch (error) {
    res.status(500).send('Gagal: ' + error.message);
  }
});

// ==========================================
// RUTE AUTENTIKASI (REGISTER & LOGIN)
// ==========================================

// --- API UNTUK REGISTER (Membuat Akun) ---
app.post('/api/register', async (req, res) => {
  try {
    const { nama, email, password, role } = req.body;

    if (!nama || !email || !password) {
      return res.status(400).json({ message: 'Nama, Email, dan Password wajib diisi!' });
    }

    // Acak password sebelum disimpan ke database
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Simpan ke Firestore
    const newUser = {
      nama: nama,
      email: email,
      password: hashedPassword, // Simpan password yang sudah diacak
      role: role || 'Siswa', // Default 'Siswa' jika tidak diisi
      waktu_daftar: new Date()
    };

    await db.collection('users').add(newUser);

    res.status(201).json({ message: 'Akun berhasil dibuat! Silakan login.' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal membuat akun', error: error.message });
  }
});

// --- API UNTUK LOGIN ---
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Cek apakah email atau password kosong
    if (!email || !password) {
      return res.status(400).json({ message: 'Email dan password wajib diisi!' });
    }

    // 2. Cari user di Firestore berdasarkan email
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', email).get();

    if (snapshot.empty) {
      return res.status(401).json({ message: 'Email tidak terdaftar!' });
    }

    // Ambil data user dari hasil pencarian
    let userData;
    let userId;
    snapshot.forEach(doc => {
      userId = doc.id;
      userData = doc.data();
    });

    // 3. Cek apakah password cocok menggunakan Bcrypt
    const isPasswordValid = await bcrypt.compare(password, userData.password);

    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Password salah!' });
    }

    // 4. Jika sukses, buatkan Token JWT
    const token = jwt.sign(
      { id: userId, role: userData.role, email: userData.email },
      process.env.JWT_SECRET || 'rahasia_cadangan',
      { expiresIn: '24h' } // Token berlaku 24 jam
    );

    // 5. Kirim balasan ke aplikasi (Flutter)
    res.status(200).json({
      message: 'Login berhasil!',
      token: token,
      user: {
        nama: userData.nama,
        role: userData.role
      }
    });

  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan di server', error: error.message });
  }
});

// ==========================================
// JALANKAN SERVER
// ==========================================
app.listen(port, () => {
  console.log(`Server Backend berjalan di http://localhost:${port}`);
});