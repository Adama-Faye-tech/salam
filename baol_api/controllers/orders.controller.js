const { query } = require('../config/database');
const notificationService = require('../services/notification.service');

/**
 * Obtenir toutes les commandes de l'utilisateur
 */
const getUserOrders = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    let queryText;
    let queryParams;

    if (userRole === 'provider') {
      // Prestataire : voir les commandes de ses équipements
      queryText = `
        SELECT o.*, e.name as equipment_name, e.image_url, u.name as client_name, u.phone as client_phone
        FROM orders o
        LEFT JOIN equipment e ON o.equipment_id = e.id
        LEFT JOIN users u ON o.client_id = u.id
        WHERE e.provider_id = $1
        ORDER BY o.created_at DESC
      `;
      queryParams = [userId];
    } else {
      // Client : voir ses propres commandes
      queryText = `
        SELECT o.*, e.name as equipment_name, e.image_url, u.name as provider_name, u.phone as provider_phone
        FROM orders o
        LEFT JOIN equipment e ON o.equipment_id = e.id
        LEFT JOIN users u ON e.provider_id = u.id
        WHERE o.client_id = $1
        ORDER BY o.created_at DESC
      `;
      queryParams = [userId];
    }

    const result = await query(queryText, queryParams);

    res.status(200).json({
      success: true,
      count: result.rows.length,
      data: result.rows,
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des commandes:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commandes',
      error: error.message,
    });
  }
};

/**
 * Obtenir les détails d'une commande
 */
const getOrderById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const result = await query(
      `SELECT o.*, e.name as equipment_name, e.image_url, e.price_per_day,
              u1.name as client_name, u1.phone as client_phone, u1.email as client_email,
              u2.name as provider_name, u2.phone as provider_phone, u2.email as provider_email
       FROM orders o
       LEFT JOIN equipment e ON o.equipment_id = e.id
       LEFT JOIN users u1 ON o.client_id = u1.id
       LEFT JOIN users u2 ON e.provider_id = u2.id
       WHERE o.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée',
      });
    }

    const order = result.rows[0];

    // Vérifier que l'utilisateur a accès à cette commande
    if (order.client_id !== userId && order.provider_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé à cette commande',
      });
    }

    res.status(200).json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de la commande:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la commande',
      error: error.message,
    });
  }
};

/**
 * Créer une nouvelle commande
 */
const createOrder = async (req, res) => {
  try {
    const clientId = req.user.id;
    const { equipmentId, startDate, endDate, totalPrice } = req.body;

    // Validation des champs requis
    if (!equipmentId || !startDate || !endDate || !totalPrice) {
      return res.status(400).json({
        success: false,
        message: 'equipmentId, startDate, endDate et totalPrice sont requis',
      });
    }

    // Vérifier que l'équipement existe et est disponible
    const equipment = await query(
      'SELECT * FROM equipment WHERE id = $1',
      [equipmentId]
    );

    if (equipment.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Équipement non trouvé',
      });
    }

    if (!equipment.rows[0].available) {
      return res.status(400).json({
        success: false,
        message: 'Cet équipement n\'est pas disponible',
      });
    }

    // Créer la commande
    const result = await query(
      `INSERT INTO orders (client_id, equipment_id, start_date, end_date, total_price, status, created_at)
       VALUES ($1, $2, $3, $4, $5, 'pending', NOW())
       RETURNING *`,
      [clientId, equipmentId, startDate, endDate, parseFloat(totalPrice)]
    );

    const order = result.rows[0];
    const providerId = equipment.rows[0].provider_id;

    // Envoyer les notifications
    await notificationService.notifyOrderCreated({
      clientId,
      providerId,
      order,
    });

    res.status(201).json({
      success: true,
      message: 'Commande créée avec succès',
      data: order,
    });
  } catch (error) {
    console.error('Erreur lors de la création de la commande:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la commande',
      error: error.message,
    });
  }
};

/**
 * Mettre à jour le statut d'une commande
 */
const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const userId = req.user.id;

    const validStatuses = ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Statut invalide. Valeurs acceptées: ${validStatuses.join(', ')}`,
      });
    }

    // Vérifier que la commande existe
    const orderCheck = await query(
      `SELECT o.*, e.provider_id 
       FROM orders o
       LEFT JOIN equipment e ON o.equipment_id = e.id
       WHERE o.id = $1`,
      [id]
    );

    if (orderCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée',
      });
    }

    const order = orderCheck.rows[0];

    // Seul le prestataire ou le client peut modifier le statut
    if (order.client_id !== userId && order.provider_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas autorisé à modifier cette commande',
      });
    }

    const result = await query(
      'UPDATE orders SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );

    const updatedOrder = result.rows[0];

    // Envoyer les notifications selon le nouveau statut
    const clientId = order.client_id;
    const providerId = order.provider_id;

    switch (status) {
      case 'confirmed':
        await notificationService.notifyOrderConfirmed({
          clientId,
          providerId,
          order: updatedOrder,
        });
        break;
      case 'in_progress':
        await notificationService.notifyOrderInProgress({
          clientId,
          providerId,
          order: updatedOrder,
        });
        break;
      case 'completed':
        await notificationService.notifyOrderCompleted({
          clientId,
          providerId,
          order: updatedOrder,
        });
        break;
      case 'cancelled':
        const cancelledBy = userId === clientId ? 'client' : 'provider';
        await notificationService.notifyOrderCancelled({
          clientId,
          providerId,
          order: updatedOrder,
          cancelledBy,
        });
        break;
    }

    res.status(200).json({
      success: true,
      message: 'Statut de la commande mis à jour',
      data: updatedOrder,
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du statut:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du statut',
      error: error.message,
    });
  }
};

/**
 * Annuler une commande
 */
const cancelOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Vérifier que la commande existe et appartient à l'utilisateur
    const orderCheck = await query(
      'SELECT * FROM orders WHERE id = $1 AND client_id = $2',
      [id, userId]
    );

    if (orderCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée ou accès refusé',
      });
    }

    const order = orderCheck.rows[0];

    if (order.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Impossible d\'annuler une commande terminée',
      });
    }

    const result = await query(
      'UPDATE orders SET status = $1 WHERE id = $2 RETURNING *',
      ['cancelled', id]
    );

    const cancelledOrder = result.rows[0];

    // Notifier l'annulation (par le client)
    await notificationService.notifyOrderCancelled({
      clientId: order.client_id,
      providerId: order.provider_id,
      order: cancelledOrder,
      cancelledBy: 'client',
    });

    res.status(200).json({
      success: true,
      message: 'Commande annulée avec succès',
      data: cancelledOrder,
    });
  } catch (error) {
    console.error('Erreur lors de l\'annulation de la commande:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'annulation de la commande',
      error: error.message,
    });
  }
};

module.exports = {
  getUserOrders,
  getOrderById,
  createOrder,
  updateOrderStatus,
  cancelOrder,
};
