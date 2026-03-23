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
        queryRef = queryRef.where(key, '==', filters[key]);
      }

      const snapshot = await queryRef
                                .limit(limit)
                                .offset(offset)
                                .get();
      const data = [];
      snapshot.forEach(doc => data.push({ id: doc.id, ...doc.data() }));
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
