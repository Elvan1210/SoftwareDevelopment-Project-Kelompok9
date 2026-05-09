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

    let list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
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

module.exports = router;