const { query } = require('../config/database');

/**
 * Obtenir les favoris de l'utilisateur
 */
const getUserFavorites = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT f.*, e.*, u.name as provider_name
       FROM favorites f
       LEFT JOIN equipment e ON f.equipment_id = e.id
       LEFT JOIN users u ON e.provider_id = u.id
       WHERE f.user_id = $1
       ORDER BY f.created_at DESC`,
      [userId]
    );

    res.status(200).json({
      success: true,
      count: result.rows.length,
      data: result.rows,
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des favoris:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des favoris',
      error: error.message,
    });
  }
};

/**
 * Ajouter un équipement aux favoris
 */
const addFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { equipmentId } = req.params;

    // Vérifier si déjà en favoris
    const existing = await query(
      'SELECT * FROM favorites WHERE user_id = $1 AND equipment_id = $2',
      [userId, equipmentId]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Cet équipement est déjà dans vos favoris',
      });
    }

    // Vérifier que l'équipement existe
    const equipment = await query(
      'SELECT id FROM equipment WHERE id = $1',
      [equipmentId]
    );

    if (equipment.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Équipement non trouvé',
      });
    }

    const result = await query(
      'INSERT INTO favorites (user_id, equipment_id, created_at) VALUES ($1, $2, NOW()) RETURNING *',
      [userId, equipmentId]
    );

    res.status(201).json({
      success: true,
      message: 'Équipement ajouté aux favoris',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Erreur lors de l\'ajout aux favoris:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'ajout aux favoris',
      error: error.message,
    });
  }
};

/**
 * Retirer un équipement des favoris
 */
const removeFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { equipmentId } = req.params;

    const result = await query(
      'DELETE FROM favorites WHERE user_id = $1 AND equipment_id = $2 RETURNING *',
      [userId, equipmentId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Favori non trouvé',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Équipement retiré des favoris',
    });
  } catch (error) {
    console.error('Erreur lors de la suppression du favori:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression du favori',
      error: error.message,
    });
  }
};

module.exports = {
  getUserFavorites,
  addFavorite,
  removeFavorite,
};
