const db = require('../config/db');

// Fungsi helper untuk meng-generate kode akses unik 8 karakter
const generateAccessCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 8; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

/**
 * Helper: Kirim notifikasi ke Firestore
 */
const sendNotification = async ({ judul, pesan, targetUserId, targetRole, targetKelas }) => {
  try {
    await db.collection('notifikasi').add({
      judul,
      pesan,
      target_user_id: targetUserId || null,
      target_role: targetRole || null,
      target_kelas: targetKelas || null,
      waktu: new Date().toISOString(),
      dibaca_oleh: [],
    });
  } catch (e) {
    // Silent fail agar tidak merusak flow utama
    console.error('Notifikasi gagal dikirim:', e.message);
  }
};

/**
 * Controller khusus untuk entitas 'Kelas'
 * Menangani logika relasional Guru & Siswa mirip Microsoft Teams.
 */
const kelasController = {
  // GET /api/kelas (dengan filter guru_id atau siswa_id)
  getAll: async (req, res) => {
    try {
      const { guru_id, siswa_id } = req.query;
      let queryRef = db.collection('kelas');

      if (guru_id) {
        queryRef = queryRef.where('guru_id', '==', guru_id);
      } else if (siswa_id) {
        queryRef = queryRef.where('siswa_ids', 'array-contains', siswa_id);
      }

      const snapshot = await queryRef.get();
      const data = [];
      snapshot.forEach(doc => data.push({ id: doc.id, ...doc.data() }));

      // Resolve guru_nama untuk setiap kelas yang punya guru_id tapi belum ada guru_nama
      for (const kelas of data) {
        if (kelas.guru_id && (!kelas.guru_nama || kelas.guru_nama === '-' || kelas.guru_nama === '')) {
          try {
            const guruDoc = await db.collection('users').doc(kelas.guru_id).get();
            if (guruDoc.exists) {
              kelas.guru_nama = guruDoc.data().nama || '-';
              // Juga update di Firestore agar next fetch tidak perlu resolve lagi
              await db.collection('kelas').doc(kelas.id).update({ guru_nama: kelas.guru_nama });
            }
          } catch (e) {
            // Ignore resolve errors
          }
        }
      }

      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/kelas
  create: async (req, res) => {
    try {
      const newKelasData = {
        ...req.body,
        kode_akses: generateAccessCode(),
        pending_requests: [],  // Initialize empty pending requests
        auto_accept: false,    // Default: perlu konfirmasi guru
      };

      const docRef = await db.collection('kelas').add(newKelasData);
      res.status(201).json({ 
        message: 'Kelas berhasil dibuat', 
        id: docRef.id,
        kode_akses: newKelasData.kode_akses 
      });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // PUT /api/kelas/:id
  update: async (req, res) => {
    try {
      await db.collection('kelas').doc(req.params.id).update(req.body);
      res.status(200).json({ message: 'Kelas berhasil diperbarui' });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // DELETE /api/kelas/:id
  remove: async (req, res) => {
    try {
      await db.collection('kelas').doc(req.params.id).delete();
      res.status(200).json({ message: 'Kelas berhasil dihapus' });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // GET /api/kelas/:id
  getById: async (req, res) => {
    try {
      const doc = await db.collection('kelas').doc(req.params.id).get();
      if (!doc.exists) return res.status(404).json({ message: 'Kelas tidak ditemukan' });
      
      const kelasData = { id: doc.id, ...doc.data() };
      
      // Resolve guru_nama jika belum ada
      if (kelasData.guru_id && (!kelasData.guru_nama || kelasData.guru_nama === '-' || kelasData.guru_nama === '')) {
        try {
          const guruDoc = await db.collection('users').doc(kelasData.guru_id).get();
          if (guruDoc.exists) {
            kelasData.guru_nama = guruDoc.data().nama || '-';
            await db.collection('kelas').doc(kelasData.id).update({ guru_nama: kelasData.guru_nama });
          }
        } catch (e) { /* ignore */ }
      }
      
      res.status(200).json(kelasData);
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/kelas/join
  joinKelasWithCode: async (req, res) => {
    try {
      const { kode_akses } = req.body;
      const userId = req.user.id || req.user.uid; 
      const userRole = req.user.role; 

      if (!kode_akses) {
        return res.status(400).json({ message: 'Kode akses diperlukan' });
      }

      // 1. Cari kelas berdasarkan kode_akses
      const kelasRef = db.collection('kelas');
      const snapshot = await kelasRef.where('kode_akses', '==', kode_akses).get();

      if (snapshot.empty) {
        return res.status(404).json({ message: 'Kode akses tidak valid atau kelas tidak ditemukan' });
      }

      // 2. Ambil data kelas tersebut
      let docId = '';
      let kelasData = {};
      snapshot.forEach(doc => {
        docId = doc.id;
        kelasData = doc.data();
      });

      const updateData = {};

      // 3. Logika pemisahan role
      if (userRole === 'siswa' || userRole === 'Siswa') {
        const currentSiswaIds = kelasData.siswa_ids || [];
        const pendingRequests = kelasData.pending_requests || [];
        
        // Cek apakah sudah terdaftar sebagai siswa
        if (currentSiswaIds.includes(userId)) {
          return res.status(400).json({ message: 'Anda sudah bergabung dalam tim/kelas ini' });
        }
        
        // Cek apakah sudah ada pending request
        if (pendingRequests.some(r => r.user_id === userId)) {
          return res.status(400).json({ message: 'Permintaan bergabung Anda sudah dikirim. Menunggu persetujuan guru.' });
        }

        // Ambil data user untuk nama dan email
        let userName = 'Siswa';
        let userEmail = '';
        try {
          const userDoc = await db.collection('users').doc(userId).get();
          if (userDoc.exists) {
            userName = userDoc.data().nama || 'Siswa';
            userEmail = userDoc.data().email || '';
          }
        } catch (e) { /* ignore */ }

        // Cek apakah auto_accept aktif
        if (kelasData.auto_accept === true) {
          // Langsung masukkan ke siswa_ids
          currentSiswaIds.push(userId);
          updateData.siswa_ids = currentSiswaIds;
          
          await db.collection('kelas').doc(docId).update(updateData);
          
          return res.status(200).json({ 
            message: 'Berhasil bergabung dengan kelas/tim!', 
            id: docId,
            status: 'accepted'
          });
        }

        // Tambahkan ke pending_requests
        pendingRequests.push({
          user_id: userId,
          nama: userName,
          email: userEmail,
          requested_at: new Date().toISOString(),
        });
        updateData.pending_requests = pendingRequests;

        await db.collection('kelas').doc(docId).update(updateData);

        // Kirim notifikasi ke guru (jika ada guru_id)
        if (kelasData.guru_id) {
          await sendNotification({
            judul: 'Permintaan Bergabung Baru',
            pesan: `${userName} ingin bergabung ke kelas "${kelasData.nama_kelas}". Silakan cek halaman Tim Anda untuk menerima atau menolak.`,
            targetUserId: kelasData.guru_id,
          });
        }

        return res.status(200).json({ 
          message: 'Permintaan bergabung telah dikirim. Menunggu persetujuan guru.', 
          id: docId,
          status: 'pending'
        });

      } else if (userRole === 'guru' || userRole === 'Guru') {
        // Ambil nama guru dari users collection
        let guruNama = '-';
        try {
          const guruDoc = await db.collection('users').doc(userId).get();
          if (guruDoc.exists) {
            guruNama = guruDoc.data().nama || '-';
          }
        } catch (e) { /* ignore */ }

        updateData.guru_id = userId;
        updateData.guru_nama = guruNama;

        await db.collection('kelas').doc(docId).update(updateData);

        return res.status(200).json({ 
          message: 'Berhasil bergabung dengan kelas/tim!', 
          id: docId,
          status: 'accepted'
        });

      } else {
        // Fallback default: anggap sebagai siswa pending
        const currentSiswaIds = kelasData.siswa_ids || [];
        const pendingRequests = kelasData.pending_requests || [];
        
        if (!currentSiswaIds.includes(userId) && !pendingRequests.some(r => r.user_id === userId)) {
          let userName = 'User';
          try {
            const userDoc = await db.collection('users').doc(userId).get();
            if (userDoc.exists) userName = userDoc.data().nama || 'User';
          } catch (e) { /* ignore */ }

          pendingRequests.push({
            user_id: userId,
            nama: userName,
            email: '',
            requested_at: new Date().toISOString(),
          });
          updateData.pending_requests = pendingRequests;
        }

        await db.collection('kelas').doc(docId).update(updateData);

        return res.status(200).json({ 
          message: 'Permintaan bergabung telah dikirim. Menunggu persetujuan guru.', 
          id: docId,
          status: 'pending'
        });
      }

    } catch (error) {
      res.status(500).json({ message: 'Gagal bergabung dengan kelas', error: error.message });
    }
  },

  // GET /api/kelas/:id/pending — Ambil daftar pending requests
  getPendingRequests: async (req, res) => {
    try {
      const doc = await db.collection('kelas').doc(req.params.id).get();
      if (!doc.exists) return res.status(404).json({ message: 'Kelas tidak ditemukan' });

      const kelasData = doc.data();
      const pendingRequests = kelasData.pending_requests || [];

      res.status(200).json({
        kelas_id: doc.id,
        nama_kelas: kelasData.nama_kelas,
        auto_accept: kelasData.auto_accept || false,
        pending_requests: pendingRequests,
      });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/kelas/:id/accept — Terima satu siswa
  acceptStudent: async (req, res) => {
    try {
      const { user_id } = req.body;
      if (!user_id) return res.status(400).json({ message: 'user_id diperlukan' });

      const docRef = db.collection('kelas').doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return res.status(404).json({ message: 'Kelas tidak ditemukan' });

      const kelasData = doc.data();
      const pendingRequests = kelasData.pending_requests || [];
      const siswaIds = kelasData.siswa_ids || [];

      // Cari dan hapus dari pending
      const requestIndex = pendingRequests.findIndex(r => r.user_id === user_id);
      if (requestIndex === -1) {
        return res.status(404).json({ message: 'Permintaan tidak ditemukan' });
      }

      const acceptedRequest = pendingRequests.splice(requestIndex, 1)[0];

      // Tambahkan ke siswa_ids jika belum ada
      if (!siswaIds.includes(user_id)) {
        siswaIds.push(user_id);
      }

      await docRef.update({
        pending_requests: pendingRequests,
        siswa_ids: siswaIds,
      });

      // Kirim notifikasi ke siswa
      await sendNotification({
        judul: 'Permintaan Diterima ✅',
        pesan: `Permintaan bergabung Anda ke kelas "${kelasData.nama_kelas}" telah diterima! Selamat bergabung.`,
        targetUserId: user_id,
      });

      res.status(200).json({ 
        message: `${acceptedRequest.nama} berhasil diterima ke dalam kelas`,
        accepted_user: acceptedRequest,
      });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/kelas/:id/reject — Tolak satu siswa
  rejectStudent: async (req, res) => {
    try {
      const { user_id } = req.body;
      if (!user_id) return res.status(400).json({ message: 'user_id diperlukan' });

      const docRef = db.collection('kelas').doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return res.status(404).json({ message: 'Kelas tidak ditemukan' });

      const kelasData = doc.data();
      const pendingRequests = kelasData.pending_requests || [];

      const requestIndex = pendingRequests.findIndex(r => r.user_id === user_id);
      if (requestIndex === -1) {
        return res.status(404).json({ message: 'Permintaan tidak ditemukan' });
      }

      const rejectedRequest = pendingRequests.splice(requestIndex, 1)[0];

      await docRef.update({
        pending_requests: pendingRequests,
      });

      // Kirim notifikasi ke siswa
      await sendNotification({
        judul: 'Permintaan Ditolak ❌',
        pesan: `Maaf, permintaan bergabung Anda ke kelas "${kelasData.nama_kelas}" ditolak oleh guru.`,
        targetUserId: user_id,
      });

      res.status(200).json({ 
        message: `${rejectedRequest.nama} telah ditolak`,
        rejected_user: rejectedRequest,
      });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/kelas/:id/accept-all — Terima semua siswa sekaligus
  acceptAllStudents: async (req, res) => {
    try {
      const docRef = db.collection('kelas').doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return res.status(404).json({ message: 'Kelas tidak ditemukan' });

      const kelasData = doc.data();
      const pendingRequests = kelasData.pending_requests || [];
      const siswaIds = kelasData.siswa_ids || [];

      if (pendingRequests.length === 0) {
        return res.status(400).json({ message: 'Tidak ada permintaan yang tertunda' });
      }

      // Pindahkan semua pending ke siswa_ids
      for (const request of pendingRequests) {
        if (!siswaIds.includes(request.user_id)) {
          siswaIds.push(request.user_id);
        }
        
        // Kirim notifikasi ke setiap siswa
        await sendNotification({
          judul: 'Permintaan Diterima ✅',
          pesan: `Permintaan bergabung Anda ke kelas "${kelasData.nama_kelas}" telah diterima! Selamat bergabung.`,
          targetUserId: request.user_id,
        });
      }

      const acceptedCount = pendingRequests.length;

      await docRef.update({
        pending_requests: [],
        siswa_ids: siswaIds,
      });

      res.status(200).json({ 
        message: `${acceptedCount} siswa berhasil diterima ke dalam kelas`,
        accepted_count: acceptedCount,
      });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // PUT /api/kelas/:id/auto-accept — Toggle auto-accept setting
  toggleAutoAccept: async (req, res) => {
    try {
      const { auto_accept } = req.body;
      
      await db.collection('kelas').doc(req.params.id).update({
        auto_accept: !!auto_accept,
      });

      res.status(200).json({ 
        message: `Auto-accept ${auto_accept ? 'diaktifkan' : 'dinonaktifkan'}`,
        auto_accept: !!auto_accept,
      });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // GET /api/kelas/:id/members — Ambil daftar anggota kelas (siswa) dengan data user
  getMembers: async (req, res) => {
    try {
      const doc = await db.collection('kelas').doc(req.params.id).get();
      if (!doc.exists) return res.status(404).json({ message: 'Kelas tidak ditemukan' });

      const kelasData = doc.data();
      const siswaIds = kelasData.siswa_ids || [];

      if (siswaIds.length === 0) {
        return res.status(200).json([]);
      }

      // Fetch user data for each siswa_id
      const members = [];
      for (const sid of siswaIds) {
        try {
          const userDoc = await db.collection('users').doc(sid).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            members.push({
              id: userDoc.id,
              nama: userData.nama || 'Siswa',
              email: userData.email || '',
              role: userData.role || 'Siswa',
            });
          } else {
            members.push({ id: sid, nama: 'Siswa (tidak ditemukan)', email: '', role: 'Siswa' });
          }
        } catch (e) {
          members.push({ id: sid, nama: 'Siswa', email: '', role: 'Siswa' });
        }
      }

      res.status(200).json(members);
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },
};

module.exports = kelasController;