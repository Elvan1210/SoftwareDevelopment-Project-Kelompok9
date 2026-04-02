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
    if (!req.file) return res.status(400).json({ message: 'Tidak ada file yang diunggah!' });

    const uniqueName = 'lampiran_' + Date.now();
    const b64 = Buffer.from(req.file.buffer).toString('base64');
    let dataURI = 'data:' + req.file.mimetype + ';base64,' + b64;

    // Deteksi apakah file adalah PDF atau bukan
    const isPdf = req.file.mimetype === 'application/pdf';

    const result = await cloudinary.uploader.upload(dataURI, {
      resource_type: isPdf ? 'raw' : 'auto', // PDF harus 'raw'
      folder: 'tugas_materi',
      public_id: isPdf ? uniqueName + '.pdf' : uniqueName,
      type: 'upload',
      access_mode: 'public',
    });

    res.status(200).json({ file_url: result.secure_url });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: 'Gagal upload', error: error.message });
  }
};

module.exports = { upload, uploadFile };