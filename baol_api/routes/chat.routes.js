const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');
const { authenticate } = require('../middleware/auth');
const { uploadImage, uploadAudio, uploadDocument, handleUploadError } = require('../middleware/upload');

/**
 * @route   GET /api/chat/conversations
 * @desc    Obtenir toutes les conversations de l'utilisateur
 * @access  Private
 */
router.get('/conversations', authenticate, chatController.getUserConversations);

/**
 * @route   GET /api/chat/:chatId
 * @desc    Obtenir les messages d'une conversation
 * @access  Private
 */
router.get('/:chatId', authenticate, chatController.getChatMessages);

/**
 * @route   POST /api/chat/create
 * @desc    Créer ou récupérer une conversation
 * @access  Private
 */
router.post('/create', authenticate, chatController.createOrGetChat);

/**
 * @route   POST /api/chat/:chatId/message
 * @desc    Envoyer un message dans une conversation
 * @access  Private
 */
router.post('/:chatId/message', authenticate, chatController.sendMessage);

/**
 * @route   PUT /api/chat/:chatId/read
 * @desc    Marquer les messages d'une conversation comme lus
 * @access  Private
 */
router.put('/:chatId/read', authenticate, chatController.markMessagesAsRead);

/**
 * @route   POST /api/chat/upload/image
 * @desc    Upload une image pour le chat
 * @access  Private
 */
router.post('/upload/image', authenticate, uploadImage, handleUploadError, chatController.uploadFile);

/**
 * @route   POST /api/chat/upload/audio
 * @desc    Upload un fichier audio pour le chat
 * @access  Private
 */
router.post('/upload/audio', authenticate, uploadAudio, handleUploadError, chatController.uploadFile);

/**
 * @route   POST /api/chat/upload/document
 * @desc    Upload un document pour le chat
 * @access  Private
 */
router.post('/upload/document', authenticate, uploadDocument, handleUploadError, chatController.uploadFile);

module.exports = router;
