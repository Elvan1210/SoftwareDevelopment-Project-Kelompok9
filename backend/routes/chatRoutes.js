const express = require('express');
const router = express.Router();
const db = require('../config/db');

// 1. Ambil daftar percakapan
router.get('/conversations/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const snapshot = await db.collection('conversations')
      .where('participants', 'array-contains', userId)
      .get();

    let list = snapshot.docs.map(doc => {
      const data = doc.data();
      const clearedAt = data.clearedFor?.[userId];

      return {
        id: doc.id,
        ...data,
        // Kalau user sudah clear chat, sembunyikan lastMessage
        lastMessage: clearedAt && new Date(data.lastUpdate) <= new Date(clearedAt)
          ? ''
          : data.lastMessage,
      };
    });

    list.sort((a, b) => new Date(b.lastUpdate) - new Date(a.lastUpdate));
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 2. Ambil semua user
router.get('/users', async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 3. Logic Chat/Grup (Anti-Duplikat)
router.post('/conversations', async (req, res) => {
  try {
    const { participants, participantNames, type, groupName } = req.body;

    if (type === 'private') {
      const existing = await db.collection('conversations')
        .where('type', '==', 'private')
        .where('participants', 'array-contains', participants[0])
        .get();

      const found = existing.docs.find(doc => {
        const p = doc.data().participants;
        return p.includes(participants[1]) && p.length === 2;
      });

      if (found) return res.json({ id: found.id, ...found.data() });
    }

    const newConv = {
      participants,
      participantNames: participantNames || {},
      type,
      name: type === 'group' ? groupName : '',
      lastMessage: 'Memulai percakapan...',
      lastUpdate: new Date().toISOString()
    };

    const docRef = await db.collection('conversations').add(newConv);
    res.json({ id: docRef.id, ...newConv });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 3b. Kirim pesan ke conversation (menggantikan socket.emit('send_message'))
router.post('/conversations/:convId/messages', async (req, res) => {
  try {
    const { convId } = req.params;
    const { senderId, senderName, text } = req.body;

    if (!text || !senderId) return res.status(400).json({ error: 'senderId dan text wajib diisi' });

    const newMessage = {
      senderId,
      senderName: senderName || 'User',
      text,
      timestamp: new Date().toISOString(),
    };

    const docRef = await db.collection('conversations').doc(convId).collection('messages').add(newMessage);
    await db.collection('conversations').doc(convId).update({
      lastMessage: text,
      lastUpdate: newMessage.timestamp,
    });

    res.status(201).json({ id: docRef.id, ...newMessage });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 4. LOGIC SALURAN / CHANNELS (MURNI TEKS JSON) - TIDAK ERROR 500 LAGI
router.post('/saluran', async (req, res) => {
  try {
    const { kelas_id, channel_id, pengirim_id, pengirim_nama, role, pesan, parentId, waktu } = req.body;

    const newMessage = {
      kelas_id,
      channel_id,
      pengirim_id,
      pengirim_nama,
      role,
      pesan: pesan || "",
      parentId: parentId || null, // Untuk fitur Reply MS Teams
      waktu: waktu || new Date().toISOString()
    };

    const docRef = await db.collection('saluran').add(newMessage);
    res.status(201).json({ id: docRef.id, ...newMessage });
  } catch (error) {
    console.error("Backend Error:", error);
    res.status(500).json({ error: "Gagal menyimpan postingan" });
  }
});

// 5. UNSEND MESSAGE (hapus untuk semua, max 2 jam)
router.delete('/messages/:conversationId/:messageId', async (req, res) => {
  try {
    const { conversationId, messageId } = req.params;
    const { senderId } = req.body;

    const msgRef = db.collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .doc(messageId);

    const msgDoc = await msgRef.get();
    if (!msgDoc.exists) return res.status(404).json({ error: 'Pesan tidak ditemukan' });

    const msg = msgDoc.data();
    if (msg.senderId !== senderId) return res.status(403).json({ error: 'Bukan pesan kamu' });

    // Batas waktu dihapus (sebelumnya max 2 jam, sekarang semua pesan bisa dihapus)

    await msgRef.update({
      text: 'Pesan ini telah dihapus',
      isUnsent: true
    });

    await db.collection('conversations').doc(conversationId).update({
      lastMessage: 'Pesan ini telah dihapus',
    });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 6. CLEAR CHAT untuk diri sendiri
router.delete('/conversations/:convId/clear', async (req, res) => {
  try {
    const { convId } = req.params;
    const { userId } = req.body;

    // Simpan timestamp clear untuk user ini
    await db.collection('conversations').doc(convId).update({
      [`clearedFor.${userId}`]: new Date().toISOString()
    });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 7. LEAVE GROUP
router.post('/conversations/:convId/leave', async (req, res) => {
  try {
    const { convId } = req.params;
    const { userId } = req.body;

    const convRef = db.collection('conversations').doc(convId);
    const convDoc = await convRef.get();
    if (!convDoc.exists) return res.status(404).json({ error: 'Grup tidak ditemukan' });

    const conv = convDoc.data();
    if (conv.type !== 'group') return res.status(400).json({ error: 'Bukan grup' });

    let participants = conv.participants.filter(p => p !== userId);
    let participantNames = { ...conv.participantNames };
    delete participantNames[userId];

    //Kalau yang leave adalah creator, alihkan ke anggota pertama yang tersisa
    let createdBy = conv.createdBy || conv.participants[0];
    if (createdBy === userId && participants.length > 0) {
      createdBy = participants[0];
    }

    if (participants.length === 0) {
      // Tidak ada anggota tersisa, hapus grup
      await convRef.delete();
      return res.json({ success: true, deleted: true });
    }

    await convRef.update({ participants, participantNames, createdBy });
    res.json({ success: true, deleted: false });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET messages untuk conversation tertentu
router.get('/conversations/:convId/messages', async (req, res) => {
  try {
    const { convId } = req.params;
    const { userId } = req.query;

    const convDoc = await db.collection('conversations').doc(convId).get();
    const clearedAt = convDoc.exists && userId
      ? convDoc.data()?.clearedFor?.[userId]
      : null;

    const snapshot = await db.collection('conversations')
      .doc(convId)
      .collection('messages')
      .get();

    let messages = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    if (clearedAt) {
      messages = messages.filter(m => new Date(m.timestamp) > new Date(clearedAt));
    }

    messages.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
    if (messages.length > 50) messages = messages.slice(messages.length - 50);

    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;