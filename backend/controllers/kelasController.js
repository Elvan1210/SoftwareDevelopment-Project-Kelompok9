// const db = require('../config/db');

// /**
//  * Controller khusus untuk entitas 'Kelas'
//  * Menangani logika relasional Guru & Siswa mirip Microsoft Teams.
//  */
// const kelasController = {
//   // GET /api/kelas (dengan filter guru_id atau siswa_id)
//   getAll: async (req, res) => {
//     try {
//       const { guru_id, siswa_id } = req.query;
//       let queryRef = db.collection('kelas');

//       if (guru_id) {
//         queryRef = queryRef.where('guru_id', '==', guru_id);
//       } else if (siswa_id) {
//         queryRef = queryRef.where('siswa_ids', 'array-contains', siswa_id);
//       }

//       const snapshot = await queryRef.get();
//       const data = [];
//       snapshot.forEach(doc => data.push({ id: doc.id, ...doc.data() }));
//       res.status(200).json(data);
//     } catch (error) {
//       res.status(500).json({ message: 'Error server', error: error.message });
//     }
//   },

//   // POST /api/kelas
//   create: async (req, res) => {
//     try {
//       // Body example: { nama_kelas, kode_kelas, mapel, guru_id, guru_nama, siswa_ids: [], warna_card }
//       const docRef = await db.collection('kelas').add(req.body);
//       res.status(201).json({ message: 'Kelas berhasil dibuat', id: docRef.id });
//     } catch (error) {
//       res.status(500).json({ message: 'Error server', error: error.message });
//     }
//   },

//   // PUT /api/kelas/:id
//   update: async (req, res) => {
//     try {
//       await db.collection('kelas').doc(req.params.id).update(req.body);
//       res.status(200).json({ message: 'Kelas berhasil diperbarui' });
//     } catch (error) {
//       res.status(500).json({ message: 'Error server', error: error.message });
//     }
//   },

//   // DELETE /api/kelas/:id
//   remove: async (req, res) => {
//     try {
//       await db.collection('kelas').doc(req.params.id).delete();
//       res.status(200).json({ message: 'Kelas berhasil dihapus' });
//     } catch (error) {
//       res.status(500).json({ message: 'Error server', error: error.message });
//     }
//   },

//   // GET /api/kelas/:id
//   getById: async (req, res) => {
//     try {
//       const doc = await db.collection('kelas').doc(req.params.id).get();
//       if (!doc.exists) return res.status(404).json({ message: 'Kelas tidak ditemukan' });
//       res.status(200).json({ id: doc.id, ...doc.data() });
//     } catch (error) {
//       res.status(500).json({ message: 'Error server', error: error.message });
//     }
//   }
// };

// module.exports = kelasController;
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
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/kelas
  create: async (req, res) => {
    try {
      // Body example: { nama_kelas, mapel, guru_id, guru_nama, siswa_ids: [], warna_card }
      const newKelasData = {
        ...req.body,
        kode_akses: generateAccessCode() // Generate kode otomatis saat dibuat
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
      res.status(200).json({ id: doc.id, ...doc.data() });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/kelas/join
  // Endpoint baru untuk bergabung ke kelas dengan kode akses
  joinKelasWithCode: async (req, res) => {
    try {
      const { kode_akses } = req.body;
      
      // Mengambil ID user dan Role dari token JWT
      // (Sesuaikan field .id atau .uid ini dengan format payload JWT Anda di auth.js)
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

      // 3. Logika pemisahan role berdasarkan user akun yang bergabung
      if (userRole === 'siswa' || userRole === 'Siswa') {
        // Ambil array siswa saat ini, jika undefined set sebagai array kosong
        const currentSiswaIds = kelasData.siswa_ids || [];
        
        // Cegah duplikasi jika user sudah ada di dalam kelas
        if (currentSiswaIds.includes(userId)) {
          return res.status(400).json({ message: 'Anda sudah bergabung dalam tim/kelas ini' });
        }
        
        currentSiswaIds.push(userId);
        updateData.siswa_ids = currentSiswaIds;

      } else if (userRole === 'guru' || userRole === 'Guru') {
        // Karena skema memakai guru_id tunggal (berdasarkan kode Anda sebelumnya),
        // ini akan menggantikan guru jika guru lain bergabung, ATAU Anda bisa memblokirnya.
        // Jika Anda ingin mendukung banyak guru, database perlu diubah menjadi array 'guru_ids'.
        // Untuk sekarang, kita perbarui guru_id menjadi user yang memasukkan kode.
        updateData.guru_id = userId;
      } else {
         // Fallback default jika role user tidak dispesifikasikan: anggap sebagai siswa
         const currentSiswaIds = kelasData.siswa_ids || [];
         if (!currentSiswaIds.includes(userId)) {
           currentSiswaIds.push(userId);
           updateData.siswa_ids = currentSiswaIds;
         }
      }

      // 4. Update data kelas di Firestore
      await db.collection('kelas').doc(docId).update(updateData);

      res.status(200).json({ 
        message: 'Berhasil bergabung dengan kelas/tim!', 
        id: docId 
      });

    } catch (error) {
      res.status(500).json({ message: 'Gagal bergabung dengan kelas', error: error.message });
    }
  }
};

module.exports = kelasController;