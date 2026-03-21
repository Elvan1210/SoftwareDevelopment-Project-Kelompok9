require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  jwtSecret: process.env.JWT_SECRET || 'fallback_rahasia_kelompok9_dev_only',
  nodeEnv: process.env.NODE_ENV || 'development'
};
