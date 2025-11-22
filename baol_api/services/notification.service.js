const { query } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

/**
 * Service de gestion des notifications
 */
class NotificationService {
  /**
   * Créer une notification dans la base de données
   */
  async createNotification({ userId, type, title, message, orderId = null }) {
    try {
      const notifId = `notif_${uuidv4()}`;
      
      await query(
        `INSERT INTO notifications (id, user_id, type, title, message, order_id, is_read, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, false, NOW())`,
        [notifId, userId, type, title, message, orderId]
      );

      console.log(`✓ Notification créée: ${title} pour user ${userId}`);
      return { success: true, id: notifId };
    } catch (error) {
      console.error('Erreur création notification:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Notification lors de la création d'une commande
   */
  async notifyOrderCreated({ clientId, providerId, order }) {
    // Notification pour le client
    await this.createNotification({
      userId: clientId,
      type: 'order_update',
      title: 'Réservation envoyée',
      message: `Votre réservation a été envoyée au prestataire. En attente de confirmation.`,
      orderId: order.id,
    });

    // Notification pour le prestataire
    await this.createNotification({
      userId: providerId,
      type: 'order_update',
      title: '🔔 Nouvelle réservation',
      message: `Vous avez reçu une nouvelle demande de réservation. Consultez-la maintenant !`,
      orderId: order.id,
    });
  }

  /**
   * Notification lors de la confirmation d'une commande
   */
  async notifyOrderConfirmed({ clientId, providerId, order }) {
    await this.createNotification({
      userId: clientId,
      type: 'order_update',
      title: '✅ Réservation confirmée',
      message: `Votre réservation a été confirmée par le prestataire ! Vous pouvez le contacter pour plus de détails.`,
      orderId: order.id,
    });
  }

  /**
   * Notification lors du début d'une commande
   */
  async notifyOrderInProgress({ clientId, providerId, order }) {
    await this.createNotification({
      userId: clientId,
      type: 'order_update',
      title: '▶️ Service en cours',
      message: `Votre réservation est maintenant en cours. Bon service !`,
      orderId: order.id,
    });
  }

  /**
   * Notification lors de la fin d'une commande
   */
  async notifyOrderCompleted({ clientId, providerId, order }) {
    // Notification pour le client
    await this.createNotification({
      userId: clientId,
      type: 'order_update',
      title: '✅ Service terminé',
      message: `Votre réservation est terminée. N'oubliez pas de laisser un avis sur le prestataire !`,
      orderId: order.id,
    });

    // Notification pour le prestataire
    await this.createNotification({
      userId: providerId,
      type: 'order_update',
      title: '✅ Service terminé',
      message: `Le service a été marqué comme terminé. Merci pour votre prestation !`,
      orderId: order.id,
    });
  }

  /**
   * Notification lors de l'annulation d'une commande
   */
  async notifyOrderCancelled({ clientId, providerId, order, cancelledBy = 'client' }) {
    if (cancelledBy === 'client') {
      // Notification pour le prestataire
      await this.createNotification({
        userId: providerId,
        type: 'order_update',
        title: '❌ Réservation annulée',
        message: `Le client a annulé sa réservation.`,
        orderId: order.id,
      });
    } else {
      // Notification pour le client
      await this.createNotification({
        userId: clientId,
        type: 'order_update',
        title: '❌ Réservation refusée',
        message: `Le prestataire a refusé votre demande de réservation. Essayez avec un autre prestataire.`,
        orderId: order.id,
      });
    }
  }

  /**
   * Notification de nouveau message
   */
  async notifyNewMessage({ userId, senderName, messagePreview }) {
    await this.createNotification({
      userId,
      type: 'message',
      title: '💬 Nouveau message',
      message: `${senderName}: ${messagePreview}`,
    });
  }
}

module.exports = new NotificationService();
