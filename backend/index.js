require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const http = require('http');
const { Server } = require('socket.io');
const logger = require('./config/logger');
const settings = require('./config/settings');
const db = require('./config/db');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST"] }
});

// ─── Global Middleware ──────────────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json());

// ─── Health check Endpoint ──────────────────────────────────────────────────
app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// ─── Import Routes ──────────────────────────────────────────────────────────
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
const chatRoutes = require('./routes/chatRoutes'); // Route Chat

// ─── Register Routes ────────────────────────────────────────────────────────
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
app.use('/api/chat', chatRoutes); // Register Chat

// ─── Socket.io Real-time & Firestore Logic ──────────────────────────────────
io.on('connection', (socket) => {
  socket.on('user_connected', (userId) => {
    socket.join(userId);
  });

  socket.on('join_chat', async (data) => {
    // Support both string dan object {conversationId, userId}
    const conversationId = typeof data === 'string' ? data : data.conversationId;
    const userId = typeof data === 'object' ? data.userId : null;

    socket.join(conversationId);
    try {
      const convDoc = await db.collection('conversations').doc(conversationId).get();
      const clearedAt = convDoc.exists && userId
        ? convDoc.data()?.clearedFor?.[userId]
        : null;

      const snapshot = await db.collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

      let history = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      // Filter pesan sebelum user clear chat
      if (clearedAt) {
        history = history.filter(m => new Date(m.timestamp) > new Date(clearedAt));
      }

      history.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
      if (history.length > 50) history = history.slice(history.length - 50);

      socket.emit('load_messages', history);
    } catch (err) { logger.error(err.message); }
  });

  // KEMBALIKAN LOGIKA INI KE PRIVATE CHAT (Bukan Saluran)
  socket.on('send_message', async (data) => {
    const { conversationId, senderId, senderName, text } = data;

    // Cegah error jika data tidak lengkap
    if (!conversationId || !text) return;

    const newMessage = { senderId, senderName, text, timestamp: new Date().toISOString() };

    try {
      // Simpan ke koleksi 'conversations', BUKAN 'saluran'
      await db.collection('conversations').doc(conversationId).collection('messages').add(newMessage);
      await db.collection('conversations').doc(conversationId).update({
        lastMessage: text,
        lastUpdate: newMessage.timestamp
      });

      io.to(conversationId).emit('receive_message', {
        id: docRef.id, 
        ...newMessage,
        conversationId
      });

      const conv = await db.collection('conversations').doc(conversationId).get();
      if (conv.exists) {
        conv.data().participants.forEach(pId => io.to(pId).emit('update_conversation_list'));
      }
    } catch (err) {
      logger.error("Gagal kirim pesan private: " + err.message);
    }
  });

  socket.on('disconnect', () => { });
});

// ─── Global Error Handling ──────────────────────────────────────────────────
app.use((err, req, res, next) => {
  logger.error(`Error processing request: ${req.method} ${req.url}`);
  res.status(500).json({ message: 'Terjadi kesalahan sistem', error: err.message });
});

// ─── Start Server ───────────────────────────────────────────────────────────
server.listen(settings.port, () => {
  logger.info(`Server Backend berjalan di http://localhost:${settings.port}`);
});