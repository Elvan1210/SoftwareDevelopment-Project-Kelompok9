const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Format: "Bearer <token>"
  if (!token) return res.status(401).json({ message: 'Akses ditolak. Token tidak ada.' });

  const settings = require('../config/settings');
  jwt.verify(token, settings.jwtSecret, (err, decoded) => {
    if (err) return res.status(403).json({ message: 'Token tidak valid atau sudah expired.' });
    req.user = decoded;
    next();
  });
};

module.exports = verifyToken;
