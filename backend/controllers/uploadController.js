const cloudinary = require('cloudinary').v2;
const multer = require('multer');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Simpan di memory sementara (Batas 20MB)
const storage = multer.memoryStorage();
const upload = multer({ storage: storage, limits: { fileSize: 20 * 1024 * 1024 } });

const uploadFile = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'Tidak ada file!' });

    const isPdf = req.file.mimetype === 'application/pdf';
    const uniqueName = 'lampiran_' + Date.now();

    // Menggunakan stream lebih stabil untuk file besar daripada Base64
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: 'tugas_materi',
        resource_type: isPdf ? 'raw' : 'auto',
        public_id: isPdf ? uniqueName + '.pdf' : uniqueName,
      },
      (error, result) => {
        if (error) return res.status(500).json({ message: 'Cloudinary Error', error });
        res.status(200).json({ file_url: result.secure_url });
      }
    );

    stream.end(req.file.buffer);
  } catch (error) {
    res.status(500).json({ message: 'Gagal upload', error: error.message });
  }
};

module.exports = { upload, uploadFile };