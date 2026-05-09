const express = require('express');
const router = express.Router();
const db = require('../config/db');

// Ambil daftar percakapan untuk user tertentu
router.get('/conversations/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const snapshot = await db.collection('conversations')
      .where('participants', 'array-contains', userId)
      .get();

    let list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    // Sortir urutan waktu secara manual
    list.sort((a, b) => new Date(b.lastUpdate) - new Date(a.lastUpdate));
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Ambil semua user untuk list
router.get('/users', async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Logic Buat Chat/Grup
router.post('/conversations', async (req, res) => {
  try {
    const { participants, participantNames, type, groupName } = req.body;
    
    // ANTI-DUPLIKAT: Jika chat pribadi, cek dulu apa sudah pernah chat
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
      name: type === 'group' ? groupName : '', // Nama hanya untuk grup
      lastMessage: 'Memulai percakapan...',
      lastUpdate: new Date().toISOString()
    };

    const docRef = await db.collection('conversations').add(newConv);
    res.json({ id: docRef.id, ...newConv });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;