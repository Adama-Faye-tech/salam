const express = require ('express');
const router = express.Router ();
const {
  uploadImage,
  uploadAudio,
  uploadDocument,
  handleUploadError,
} = require ('../middleware/upload');
const {authenticate} = require ('../middleware/auth');

/**
 * @route   POST /api/upload/image
 * @desc    Upload une image (équipement, profil, etc.)
 * @access  Private
 */
router.post ('/image', authenticate, (req, res, next) => {
  uploadImage (req, res, err => {
    if (err) {
      return handleUploadError (err, req, res, next);
    }

    if (!req.file) {
      return res.status (400).json ({
        success: false,
        message: 'Aucun fichier fourni',
      });
    }

    const fileUrl = `${req.protocol}://${req.get ('host')}/uploads/images/${req.file.filename}`;

    res.status (200).json ({
      success: true,
      message: 'Image uploadée avec succès',
      file: {
        filename: req.file.filename,
        originalName: req.file.originalname,
        url: fileUrl,
        size: req.file.size,
        mimetype: req.file.mimetype,
      },
    });
  });
});

/**
 * @route   POST /api/upload/audio
 * @desc    Upload un fichier audio (message vocal, etc.)
 * @access  Private
 */
router.post ('/audio', authenticate, (req, res, next) => {
  uploadAudio (req, res, err => {
    if (err) {
      return handleUploadError (err, req, res, next);
    }

    if (!req.file) {
      return res.status (400).json ({
        success: false,
        message: 'Aucun fichier fourni',
      });
    }

    const fileUrl = `${req.protocol}://${req.get ('host')}/uploads/audio/${req.file.filename}`;

    res.status (200).json ({
      success: true,
      message: 'Audio uploadé avec succès',
      file: {
        filename: req.file.filename,
        originalName: req.file.originalname,
        url: fileUrl,
        size: req.file.size,
        mimetype: req.file.mimetype,
      },
    });
  });
});

/**
 * @route   POST /api/upload/document
 * @desc    Upload un document (facture, contrat, etc.)
 * @access  Private
 */
router.post ('/document', authenticate, (req, res, next) => {
  uploadDocument (req, res, err => {
    if (err) {
      return handleUploadError (err, req, res, next);
    }

    if (!req.file) {
      return res.status (400).json ({
        success: false,
        message: 'Aucun fichier fourni',
      });
    }

    const fileUrl = `${req.protocol}://${req.get ('host')}/uploads/documents/${req.file.filename}`;

    res.status (200).json ({
      success: true,
      message: 'Document uploadé avec succès',
      file: {
        filename: req.file.filename,
        originalName: req.file.originalname,
        url: fileUrl,
        size: req.file.size,
        mimetype: req.file.mimetype,
      },
    });
  });
});

module.exports = router;
