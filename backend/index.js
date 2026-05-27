require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const http = require('http');
const logger = require('./config/logger');
const settings = require('./config/settings');

const app = express();
const server = http.createServer(app);

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const kelasRoutes = require('./routes/kelasRoutes');
const tugasRoutes = require('./routes/tugasRoutes');
const materiRoutes = require('./routes/materiRoutes');
const nilaiRoutes = require('./routes/nilaiRoutes');
const pengumumanRoutes = require('./routes/pengumumanRoutes');
const pengumpulanRoutes = require('./routes/pengumpulanRoutes');
const notifikasiRoutes = require('./routes/notifikasiRoutes');
const presensiRoutes = require('./routes/presensiRoutes');
const saluranRoutes = require('./routes/saluranRoutes');
const channelRoutes = require('./routes/channelRoutes');
const quizRoutes = require('./routes/quizRoutes');
const chatRoutes = require('./routes/chatRoutes');

app.use('/api', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/kelas', kelasRoutes);
app.use('/api/tugas', tugasRoutes);
app.use('/api/materi', materiRoutes);
app.use('/api/nilai', nilaiRoutes);
app.use('/api/pengumuman', pengumumanRoutes);
app.use('/api/pengumpulan', pengumpulanRoutes);
app.use('/api/notifikasi', notifikasiRoutes);
app.use('/api/presensi', presensiRoutes);
app.use('/api/saluran', saluranRoutes);
app.use('/api/channels', channelRoutes);
app.use('/api/quiz', quizRoutes);
app.use('/api/chat', chatRoutes);


app.use((err, req, res, next) => {
  logger.error(`Error processing request: ${req.method} ${req.url}`);
  res.status(500).json({ message: 'Terjadi kesalahan sistem', error: err.message });
});

if (process.env.NODE_ENV !== 'production') {
  const settings = require('./config/settings');
  server.listen(settings.port, () => {
    logger.info(`Server Backend berjalan di http://localhost:${settings.port}`);
  });
}

module.exports = app;