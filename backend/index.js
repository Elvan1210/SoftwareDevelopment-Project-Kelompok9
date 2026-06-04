require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./config/logger');

const app = express();

// ── Middleware ────────────────────────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Health check (untuk Vercel cron keep-alive) ───────────────────────────────
app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// ── Routes ─────────────────────────────────────────────────────────────────────
// Lazy-load routes agar cold start lebih ringan (hanya load route yang diminta)
app.use('/api', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/kelas', require('./routes/kelasRoutes'));
app.use('/api/tugas', require('./routes/tugasRoutes'));
app.use('/api/materi', require('./routes/materiRoutes'));
app.use('/api/nilai', require('./routes/nilaiRoutes'));
app.use('/api/pengumuman', require('./routes/pengumumanRoutes'));
app.use('/api/pengumpulan', require('./routes/pengumpulanRoutes'));
app.use('/api/notifikasi', require('./routes/notifikasiRoutes'));
app.use('/api/presensi', require('./routes/presensiRoutes'));
app.use('/api/saluran', require('./routes/saluranRoutes'));
app.use('/api/channels', require('./routes/channelRoutes'));
app.use('/api/quiz', require('./routes/quizRoutes'));
app.use('/api/chat', require('./routes/chatRoutes'));

// ── Global error handler ───────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  logger.error(`Error: ${req.method} ${req.url} — ${err.message}`);
  res.status(500).json({ message: 'Terjadi kesalahan sistem', error: err.message });
});

// ── Start server (hanya di dev lokal, BUKAN di Vercel) ────────────────────────
if (process.env.NODE_ENV !== 'production') {
  const settings = require('./config/settings');
  const http = require('http');
  const server = http.createServer(app);
  server.listen(settings.port, () => {
    logger.info(`Server Backend berjalan di http://localhost:${settings.port}`);
  });
}

module.exports = app;