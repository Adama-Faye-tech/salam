const { query } = require('../config/database');

/**
 * Récupérer toutes les notifications d'un utilisateur
 */
const getUserNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT * FROM notifications 
       WHERE user_id = $1 
       ORDER BY created_at DESC 
       LIMIT 50`,
      [userId]
    );

    res.status(200).json({
      success: true,
      count: result.rows.length,
      data: result.rows,
    });
  } catch (error) {
    console.error('Erreur récupération notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des notifications',
      error: error.message,
    });
  }
};

/**
 * Compter les notifications non lues
 */
const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT COUNT(*) as count FROM notifications 
       WHERE user_id = $1 AND is_read = false`,
      [userId]
    );

    res.status(200).json({
      success: true,
      count: parseInt(result.rows[0].count),
    });
  } catch (error) {
    console.error('Erreur comptage notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du comptage des notifications',
      error: error.message,
    });
  }
};

/**
 * Marquer une notification comme lue
 */
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Vérifier que la notification appartient à l'utilisateur
    const checkResult = await query(
      'SELECT * FROM notifications WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification non trouvée',
      });
    }

    await query(
      'UPDATE notifications SET is_read = true WHERE id = $1',
      [id]
    );

    res.status(200).json({
      success: true,
      message: 'Notification marquée comme lue',
    });
  } catch (error) {
    console.error('Erreur marquage notification:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du marquage de la notification',
      error: error.message,
    });
  }
};

/**
 * Marquer toutes les notifications comme lues
 */
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    await query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1',
      [userId]
    );

    res.status(200).json({
      success: true,
      message: 'Toutes les notifications ont été marquées comme lues',
    });
  } catch (error) {
    console.error('Erreur marquage toutes notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du marquage des notifications',
      error: error.message,
    });
  }
};

/**
 * Supprimer une notification
 */
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Vérifier que la notification appartient à l'utilisateur
    const checkResult = await query(
      'SELECT * FROM notifications WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification non trouvée',
      });
    }

    await query('DELETE FROM notifications WHERE id = $1', [id]);

    res.status(200).json({
      success: true,
      message: 'Notification supprimée',
    });
  } catch (error) {
    console.error('Erreur suppression notification:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de la notification',
      error: error.message,
    });
  }
};

/**
 * Supprimer toutes les notifications lues
 */
const deleteReadNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'DELETE FROM notifications WHERE user_id = $1 AND is_read = true',
      [userId]
    );

    res.status(200).json({
      success: true,
      message: `${result.rowCount} notification(s) supprimée(s)`,
      count: result.rowCount,
    });
  } catch (error) {
    console.error('Erreur suppression notifications lues:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression des notifications',
      error: error.message,
    });
  }
};

module.exports = {
  getUserNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  deleteReadNotifications,
};
