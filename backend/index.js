require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// ─── Global Middleware ──────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── Import Routes ──────────────────────────────────────────────────────────
const authRoutes        = require('./routes/authRoutes');
const userRoutes        = require('./routes/userRoutes');
const kelasRoutes       = require('./routes/kelasRoutes');
const tugasRoutes       = require('./routes/tugasRoutes');
const materiRoutes      = require('./routes/materiRoutes');
const nilaiRoutes       = require('./routes/nilaiRoutes');
const pengumumanRoutes  = require('./routes/pengumumanRoutes');
const pengumpulanRoutes = require('./routes/pengumpulanRoutes');
const notifikasiRoutes  = require('./routes/notifikasiRoutes');

// ─── Register Routes ────────────────────────────────────────────────────────
app.use('/api',             authRoutes);
app.use('/api/users',       userRoutes);
app.use('/api/kelas',       kelasRoutes);
app.use('/api/tugas',       tugasRoutes);
app.use('/api/materi',      materiRoutes);
app.use('/api/nilai',       nilaiRoutes);
app.use('/api/pengumuman',  pengumumanRoutes);
app.use('/api/pengumpulan', pengumpulanRoutes);
app.use('/api/notifikasi',  notifikasiRoutes);

// ─── Start Server ───────────────────────────────────────────────────────────
app.listen(port, () => {
  console.log(`Server Backend berjalan di http://localhost:${port}`);
});