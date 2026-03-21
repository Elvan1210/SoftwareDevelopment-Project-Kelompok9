require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./config/logger');
const settings = require('./config/settings');

const app = express();

// ─── Global Middleware ──────────────────────────────────────────────────────
app.use(helmet()); // Secure HTTP headers against vulnerabilities like XSS
app.use(cors());
app.use(express.json());

// ─── Health check Endpoint ──────────────────────────────────────────────────
app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

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

// ─── Global Error Handling ──────────────────────────────────────────────────
app.use((err, req, res, next) => {
  logger.error(`Error processing request: ${req.method} ${req.url}`, {
    error: err.message,
    stack: err.stack,
    ip: req.ip
  });
  res.status(500).json({ message: 'Terjadi kesalahan sistem', error: settings.nodeEnv === 'development' ? err.message : null });
});

// ─── Start Server ───────────────────────────────────────────────────────────
app.listen(settings.port, () => {
  logger.info(`Server Backend berjalan dengan aman di http://localhost:${settings.port}`);
});