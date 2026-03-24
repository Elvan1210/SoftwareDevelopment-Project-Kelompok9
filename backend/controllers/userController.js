const bcrypt = require('bcryptjs');
const db = require('../config/db');

// GET /api/users
exports.getAll = async (req, res) => {
  try {
    const { role } = req.query;
    let queryRef = db.collection('users');
    if (role) {
      queryRef = queryRef.where('role', '==', role);
    }
    const snapshot = await queryRef.get();
    const users = [];
    snapshot.forEach(doc => users.push({ id: doc.id, ...doc.data() }));
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
};

// POST /api/users
exports.create = async (req, res) => {
  try {
    const { nama, email, password, role, kelas } = req.body;
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const newUser = { nama, email, password: hashedPassword, role, kelas: kelas || '', waktu_daftar: new Date() };
    const docRef = await db.collection('users').add(newUser);
    res.status(201).json({ message: 'User dibuat', id: docRef.id });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
};

// PUT /api/users/:id
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, email, role, password, kelas } = req.body;
    const updateData = { nama, email, role, kelas };
    if (password && password.trim() !== '') {
      const salt = await bcrypt.genSalt(10);
      updateData.password = await bcrypt.hash(password, salt);
    }
    await db.collection('users').doc(id).update(updateData);
    res.status(200).json({ message: 'User diupdate' });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
};

// DELETE /api/users/:id
exports.remove = async (req, res) => {
  try {
    await db.collection('users').doc(req.params.id).delete();
    res.status(200).json({ message: 'User dihapus' });
  } catch (error) {
    res.status(500).json({ message: 'Error server', error: error.message });
  }
};
