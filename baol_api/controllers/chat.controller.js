const { query, getClient } = require('../config/database');
const { getFileUrl } = require('../middleware/upload');

/**
 * Obtenir toutes les conversations de l'utilisateur
 */
const getUserConversations = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT 
        c.*,
        u1.name as client_name,
        u2.name as provider_name,
        e.name as equipment_name,
        e.image_url as equipment_image,
        (SELECT content FROM messages WHERE chat_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message,
        (SELECT created_at FROM messages WHERE chat_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message_time,
        (SELECT COUNT(*) FROM messages WHERE chat_id = c.id AND sender_id != $1 AND read_at IS NULL) as unread_count
       FROM chats c
       LEFT JOIN users u1 ON c.client_id = u1.id
       LEFT JOIN users u2 ON c.provider_id = u2.id
       LEFT JOIN equipment e ON c.equipment_id = e.id
       WHERE c.client_id = $1 OR c.provider_id = $1
       ORDER BY last_message_time DESC NULLS LAST`,
      [userId]
    );

    const conversations = result.rows.map(chat => ({
      ...chat,
      equipment_image: chat.equipment_image ? getFileUrl(chat.equipment_image) : null,
    }));

    res.status(200).json({
      success: true,
      count: conversations.length,
      data: conversations,
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des conversations:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des conversations',
      error: error.message,
    });
  }
};

/**
 * Obtenir les messages d'une conversation
 */
const getChatMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;

    // Vérifier que l'utilisateur fait partie de cette conversation
    const chatCheck = await query(
      'SELECT * FROM chats WHERE id = $1 AND (client_id = $2 OR provider_id = $2)',
      [chatId, userId]
    );

    if (chatCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé à cette conversation',
      });
    }

    const result = await query(
      `SELECT m.*, u.name as sender_name
       FROM messages m
       LEFT JOIN users u ON m.sender_id = u.id
       WHERE m.chat_id = $1
       ORDER BY m.created_at ASC`,
      [chatId]
    );

    const messages = result.rows.map(message => ({
      ...message,
      file_url: message.file_url ? getFileUrl(message.file_url) : null,
    }));

    res.status(200).json({
      success: true,
      count: messages.length,
      data: messages,
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des messages:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des messages',
      error: error.message,
    });
  }
};

/**
 * Créer ou récupérer une conversation
 */
const createOrGetChat = async (req, res) => {
  try {
    const clientId = req.user.id;
    const { providerId, equipmentId } = req.body;

    if (!providerId || !equipmentId) {
      return res.status(400).json({
        success: false,
        message: 'providerId et equipmentId sont requis',
      });
    }

    // Vérifier si une conversation existe déjà
    const existingChat = await query(
      `SELECT * FROM chats 
       WHERE client_id = $1 AND provider_id = $2 AND equipment_id = $3`,
      [clientId, providerId, equipmentId]
    );

    if (existingChat.rows.length > 0) {
      return res.status(200).json({
        success: true,
        message: 'Conversation existante récupérée',
        data: existingChat.rows[0],
      });
    }

    // Créer une nouvelle conversation
    const result = await query(
      `INSERT INTO chats (client_id, provider_id, equipment_id, created_at)
       VALUES ($1, $2, $3, NOW())
       RETURNING *`,
      [clientId, providerId, equipmentId]
    );

    res.status(201).json({
      success: true,
      message: 'Conversation créée avec succès',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Erreur lors de la création de la conversation:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la conversation',
      error: error.message,
    });
  }
};

/**
 * Envoyer un message
 */
const sendMessage = async (req, res) => {
  try {
    const { chatId } = req.params;
    const senderId = req.user.id;
    const { type, content, fileUrl } = req.body;

    // Vérifier que l'utilisateur fait partie de cette conversation
    const chatCheck = await query(
      'SELECT * FROM chats WHERE id = $1 AND (client_id = $2 OR provider_id = $2)',
      [chatId, senderId]
    );

    if (chatCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé à cette conversation',
      });
    }

    // Validation selon le type
    if (type === 'text' && !content) {
      return res.status(400).json({
        success: false,
        message: 'Le contenu est requis pour un message texte',
      });
    }

    if (['image', 'audio', 'document'].includes(type) && !fileUrl) {
      return res.status(400).json({
        success: false,
        message: 'L\'URL du fichier est requise pour ce type de message',
      });
    }

    // Insérer le message
    const result = await query(
      `INSERT INTO messages (chat_id, sender_id, type, content, file_url, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING *`,
      [chatId, senderId, type, content || null, fileUrl || null]
    );

    const message = result.rows[0];
    message.file_url = message.file_url ? getFileUrl(message.file_url) : null;

    res.status(201).json({
      success: true,
      message: 'Message envoyé avec succès',
      data: message,
    });
  } catch (error) {
    console.error('Erreur lors de l\'envoi du message:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi du message',
      error: error.message,
    });
  }
};

/**
 * Marquer les messages comme lus
 */
const markMessagesAsRead = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;

    // Vérifier que l'utilisateur fait partie de cette conversation
    const chatCheck = await query(
      'SELECT * FROM chats WHERE id = $1 AND (client_id = $2 OR provider_id = $2)',
      [chatId, userId]
    );

    if (chatCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé à cette conversation',
      });
    }

    // Marquer tous les messages non lus comme lus
    const result = await query(
      `UPDATE messages 
       SET read_at = NOW()
       WHERE chat_id = $1 
         AND sender_id != $2 
         AND read_at IS NULL
       RETURNING id`,
      [chatId, userId]
    );

    res.status(200).json({
      success: true,
      message: `${result.rowCount} message(s) marqué(s) comme lu(s)`,
      count: result.rowCount,
    });
  } catch (error) {
    console.error('Erreur lors du marquage des messages:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du marquage des messages',
      error: error.message,
    });
  }
};

/**
 * Upload d'un fichier (appelé avant sendMessage)
 */
const uploadFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier uploadé',
      });
    }

    const fileUrl = getFileUrl(req.file.path);

    res.status(200).json({
      success: true,
      message: 'Fichier uploadé avec succès',
      data: {
        fileUrl,
        fileName: req.file.originalname,
        fileSize: req.file.size,
        mimeType: req.file.mimetype,
        path: req.file.path,
      },
    });
  } catch (error) {
    console.error('Erreur lors de l\'upload:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'upload',
      error: error.message,
    });
  }
};

module.exports = {
  getUserConversations,
  getChatMessages,
  createOrGetChat,
  sendMessage,
  markMessagesAsRead,
  uploadFile,
};
