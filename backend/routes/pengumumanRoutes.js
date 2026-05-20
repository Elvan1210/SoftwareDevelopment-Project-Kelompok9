const router = require('express').Router();
const verifyToken = require('../middleware/auth');
const { requireRole } = require('../middleware/rbac');
const createCrudController = require('../controllers/genericCrudController');
const db = require('../config/db');
const admin = require('firebase-admin');

const ctrl = createCrudController('pengumuman');

// GET — semua role bisa baca
router.get('/', verifyToken, ctrl.getAll);

// PUT/DELETE — Guru & Admin
router.put('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.update);
router.delete('/:id', verifyToken, requireRole('Guru', 'Admin'), ctrl.remove);

// POST — custom: simpan pengumuman + kirim notifikasi ke siswa
router.post('/', verifyToken, requireRole('Guru', 'Admin'), async (req, res) => {
    try {
        const {
            judul,
            isi,
            guru_id,
            nama_guru,
            kelas_ids,    // array of kelas_id yang dipilih
            channel_ids,  // array of channel_id yang dipilih (opsional)
        } = req.body;

        if (!judul || !isi) {
            return res.status(400).json({ message: 'Judul dan isi pengumuman wajib diisi' });
        }

        const now = new Date().toISOString();

        // 1. Simpan pengumuman ke Firestore
        const pengRef = await db.collection('pengumuman').add({
            judul,
            isi,
            guru_id: guru_id || req.user.id,
            nama_guru: nama_guru || '',
            kelas_ids: kelas_ids || [],
            channel_ids: channel_ids || [],
            created_at: now,
            updated_at: now,
        });

        // 2. Kumpulkan semua siswa dari kelas yang dipilih
        const siswaIds = new Set();
        if (kelas_ids && kelas_ids.length > 0) {
            for (const kelasId of kelas_ids) {
                const kelasDoc = await db.collection('kelas').doc(kelasId).get();
                if (kelasDoc.exists) {
                    const siswaList = kelasDoc.data().siswa_ids || [];
                    siswaList.forEach(id => siswaIds.add(id));
                }
            }
        }

        // 3. Batch write notifikasi ke setiap siswa
        if (siswaIds.size > 0) {
            const batch = db.batch();
            for (const siswaId of siswaIds) {
                const notifRef = db.collection('notifikasi').doc();
                batch.set(notifRef, {
                    user_id: siswaId,
                    judul: `Pengumuman: ${judul}`,
                    isi: isi.length > 100 ? isi.substring(0, 100) + '...' : isi,
                    type: 'pengumuman',
                    ref_id: pengRef.id,
                    is_read: false,
                    created_at: now,
                });
            }
            await batch.commit();
        }

        // 4. Post ke channel sebagai pesan
        if (channel_ids && channel_ids.length > 0) {
            const batch2 = db.batch(); // ← pastikan ada di sini
            for (const channelId of channel_ids) {
                const isGeneral = channelId.startsWith('general_');
                const actualKelasId = isGeneral
                    ? channelId.replace('general_', '')
                    : null;

                const msgRef = db.collection('saluran').doc();
                batch2.set(msgRef, {
                    channel_id: isGeneral ? 'general' : channelId,
                    kelas_id: isGeneral ? actualKelasId : (kelas_ids?.[0] || ''),
                    tipe: 'pengumuman',
                    pengumuman_id: pengRef.id,
                    pesan: isi,
                    pengirim_id: guru_id || req.user.id,
                    pengirim_nama: nama_guru || '',
                    role: 'Guru',
                    waktu: now,
                    parentId: null,
                });
            }
            await batch2.commit();
        }

        res.status(201).json({
            message: 'Pengumuman berhasil dikirim',
            id: pengRef.id,
            notified: siswaIds.size,
        });
    } catch (error) {
        console.error('Error create pengumuman:', error);
        res.status(500).json({ message: 'Error server', error: error.message });
    }
});

module.exports = router;