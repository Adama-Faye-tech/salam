const express = require('express');
const router = express.Router();
const favoritesController = require('../controllers/favorites.controller');
const { authenticate } = require('../middleware/auth');

/**
 * @route   GET /api/favorites
 * @desc    Obtenir les favoris de l'utilisateur
 * @access  Private
 */
router.get('/', authenticate, favoritesController.getUserFavorites);

/**
 * @route   POST /api/favorites/:equipmentId
 * @desc    Ajouter un équipement aux favoris
 * @access  Private
 */
router.post('/:equipmentId', authenticate, favoritesController.addFavorite);

/**
 * @route   DELETE /api/favorites/:equipmentId
 * @desc    Retirer un équipement des favoris
 * @access  Private
 */
router.delete('/:equipmentId', authenticate, favoritesController.removeFavorite);

module.exports = router;
