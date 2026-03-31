/**
 * Role-Based Access Control (RBAC) Middleware
 *
 * Factory function yang menghasilkan middleware Express untuk membatasi akses
 * berdasarkan role pengguna dari JWT token yang sudah diverifikasi.
 *
 * Role yang valid di sistem ini adalah: 'Admin', 'Guru', 'Siswa' (Capitalized).
 * Middleware ini bersifat case-insensitive agar toleran terhadap inkonsistensi data lama.
 *
 * Penggunaan:
 *   const { requireRole } = require('../middleware/rbac');
 *   router.post('/', verifyToken, requireRole('Admin', 'Guru'), ctrl.create);
 *
 * @param {...string} allowedRoles - Satu atau lebih role yang diizinkan mengakses rute ini.
 */
const requireRole = (...allowedRoles) => {
  // Normalisasi semua allowed roles ke lowercase untuk perbandingan
  const normalizedAllowed = allowedRoles.map(r => r.toLowerCase());

  return (req, res, next) => {
    // req.user seharusnya sudah di-attach oleh middleware verifyToken sebelumnya
    if (!req.user || !req.user.role) {
      return res.status(403).json({
        message: 'Akses ditolak. Informasi role pengguna tidak ditemukan dalam token.',
      });
    }

    const userRole = req.user.role.toLowerCase();

    if (!normalizedAllowed.includes(userRole)) {
      return res.status(403).json({
        message: `Akses ditolak. Rute ini hanya untuk: ${allowedRoles.join(', ')}.`,
      });
    }

    next();
  };
};

module.exports = { requireRole };
