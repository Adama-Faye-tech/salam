const express = require('express');
const router = express.Router();
const {
  getUserNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  deleteReadNotifications,
} = require('../controllers/notifications.controller');
const { authenticate } = require('../middleware/auth');

// Toutes les routes nécessitent l'authentification
router.use(authenticate);

// GET /api/notifications - Récupérer toutes les notifications de l'utilisateur
router.get('/', getUserNotifications);

// GET /api/notifications/unread-count - Compter les notifications non lues
router.get('/unread-count', getUnreadCount);

// PUT /api/notifications/:id/read - Marquer une notification comme lue
router.put('/:id/read', markAsRead);

// PUT /api/notifications/mark-all-read - Marquer toutes comme lues
router.put('/mark-all-read', markAllAsRead);

// DELETE /api/notifications/:id - Supprimer une notification
router.delete('/:id', deleteNotification);

// DELETE /api/notifications/read/all - Supprimer toutes les notifications lues
router.delete('/read/all', deleteReadNotifications);

module.exports = router;
