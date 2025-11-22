const multer = require('multer');
const path = require('path');
const fs = require('fs');

// S'assurer que les dossiers d'upload existent
const uploadDirs = [
  'uploads/images',
  'uploads/audio',
  'uploads/documents',
];

uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Configuration de stockage pour les images
 */
const imageStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/images');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

/**
 * Configuration de stockage pour les audios
 */
const audioStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/audio');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

/**
 * Configuration de stockage pour les documents
 */
const documentStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/documents');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

/**
 * Filtres de fichiers par type
 */
const imageFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif|webp/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Seules les images (JPEG, JPG, PNG, GIF, WEBP) sont autorisées'));
  }
};

const audioFilter = (req, file, cb) => {
  const allowedTypes = /mp3|wav|m4a|aac|ogg/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = /audio/.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Seuls les fichiers audio (MP3, WAV, M4A, AAC, OGG) sont autorisés'));
  }
};

const documentFilter = (req, file, cb) => {
  const allowedTypes = /pdf|doc|docx|txt|xls|xlsx|ppt|pptx/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());

  if (extname) {
    return cb(null, true);
  } else {
    cb(new Error('Seuls les documents (PDF, DOC, DOCX, TXT, XLS, XLSX, PPT, PPTX) sont autorisés'));
  }
};

/**
 * Middleware Multer configurés
 */
const uploadImage = multer({
  storage: imageStorage,
  fileFilter: imageFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE_IMAGE) || 5 * 1024 * 1024, // 5MB par défaut
  },
}).single('file');

const uploadAudio = multer({
  storage: audioStorage,
  fileFilter: audioFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE_AUDIO) || 10 * 1024 * 1024, // 10MB par défaut
  },
}).single('file');

const uploadDocument = multer({
  storage: documentStorage,
  fileFilter: documentFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE_DOCUMENT) || 20 * 1024 * 1024, // 20MB par défaut
  },
}).single('file');

/**
 * Middleware pour gérer les erreurs Multer
 */
const handleUploadError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'Fichier trop volumineux',
        maxSize: err.field === 'image' ? '5MB' : err.field === 'audio' ? '10MB' : '20MB',
      });
    }

    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      return res.status(400).json({
        success: false,
        message: 'Champ de fichier inattendu',
      });
    }

    return res.status(400).json({
      success: false,
      message: 'Erreur lors de l\'upload',
      error: err.message,
    });
  }

  if (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }

  next();
};

/**
 * Fonction helper pour supprimer un fichier
 */
const deleteFile = (filePath) => {
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      console.log('Fichier supprimé:', filePath);
      return true;
    }
    return false;
  } catch (error) {
    console.error('Erreur lors de la suppression du fichier:', error);
    return false;
  }
};

/**
 * Fonction helper pour obtenir l'URL complète d'un fichier
 */
const getFileUrl = (filePath) => {
  const apiUrl = process.env.API_URL || 'http://localhost:3000';
  return `${apiUrl}/${filePath.replace(/\\/g, '/')}`;
};

module.exports = {
  uploadImage,
  uploadAudio,
  uploadDocument,
  handleUploadError,
  deleteFile,
  getFileUrl,
};
