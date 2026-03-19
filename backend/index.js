const express = require('express');
// Memanggil koneksi database dari folder config
const db = require('./config/db');

const app = express();
const port = 3000;

app.use(express.json());

// Route untuk halaman depan (root)
app.get('/', (req, res) => {
  res.send('Selamat datang di API MyPSKD! Server berjalan normal. 🚀');
});

// API Route untuk test tambah data ke Firestore
app.get('/test-tambah', async (req, res) => {
  try {
    const userRef = db.collection('users').doc('test_01');
    await userRef.set({
      nama: 'Elvan Mariano',
      role: 'Siswa',
      waktu_daftar: new Date()
    });
    
    res.send('Sukses! Data Elvan berhasil masuk ke Firestore! 🚀');
  } catch (error) {
    res.status(500).send('Gagal: ' + error.message);
  }
});

app.listen(port, () => {
  console.log(`Server Backend berjalan di http://localhost:${port}`);
});