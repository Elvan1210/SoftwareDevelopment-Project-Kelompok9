const db = require('../config/db');

/**
 * Factory function: menghasilkan object controller CRUD 
 * untuk koleksi Firestore manapun.
 * 
 * Penggunaan: const ctrl = createCrudController('tugas');
 */
const createCrudController = (collectionName) => ({
  // GET /api/:collection
  getAll: async (req, res) => {
    try {
      const limit = parseInt(req.query.limit) || 50;
      const offset = parseInt(req.query.offset) || 0;
      
      let queryRef = db.collection(collectionName);
      
      const filters = { ...req.query };
      delete filters.limit;
      delete filters.offset;
      
      // Dukungan untuk OR query pada 'kelas' dan 'mapel'
      if (filters.kelas_or_mapel) {
        const { Filter } = require('firebase-admin/firestore');
        queryRef = queryRef.where(
          Filter.or(
            Filter.where('kelas', '==', filters.kelas_or_mapel),
            Filter.where('mapel', '==', filters.kelas_or_mapel)
          )
        );
        delete filters.kelas_or_mapel;
      }
      
      for (const key in filters) {
        if (key === 'start_date' || key === 'end_date') continue;
        queryRef = queryRef.where(key, '==', filters[key]);
      }

      const snapshot = await queryRef
                                .limit(limit)
                                .offset(offset)
                                .get();
      let data = [];
      snapshot.forEach(doc => data.push({ id: doc.id, ...doc.data() }));

      // In-memory filter for start_date and end_date
      if (req.query.start_date || req.query.end_date) {
        data = data.filter(item => {
          if (!item.tanggal) return true; // if no date, don't filter out or decide policy. We'll allow it.
          const itemDate = new Date(item.tanggal);
          if (req.query.start_date) {
            const start = new Date(req.query.start_date);
            if (itemDate < start) return false;
          }
          if (req.query.end_date) {
            const end = new Date(req.query.end_date);
            if (itemDate > end) return false;
          }
          return true;
        });
      }

      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // POST /api/:collection
  create: async (req, res) => {
    try {
      const docRef = await db.collection(collectionName).add(req.body);
      res.status(201).json({ message: 'Data dibuat', id: docRef.id });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // PUT /api/:collection/:id
  update: async (req, res) => {
    try {
      await db.collection(collectionName).doc(req.params.id).update(req.body);
      res.status(200).json({ message: 'Data diupdate' });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },

  // DELETE /api/:collection/:id
  remove: async (req, res) => {
    try {
      await db.collection(collectionName).doc(req.params.id).delete();
      res.status(200).json({ message: 'Data dihapus' });
    } catch (error) {
      res.status(500).json({ message: 'Error server', error: error.message });
    }
  },
});

module.exports = createCrudController;
