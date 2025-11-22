const express = require('express');
const router = express.Router();
const equipmentController = require('../controllers/equipment.controller');
const { authenticate, optionalAuth } = require('../middleware/auth');

/**
 * @route   GET /api/equipment
 * @desc    Obtenir tous les équipements (avec filtres optionnels)
 * @query   category, minPrice, maxPrice, search, providerId
 * @access  Public
 */
router.get('/', optionalAuth, equipmentController.getAllEquipment);

/**
 * @route   GET /api/equipment/:id
 * @desc    Obtenir les détails d'un équipement
 * @access  Public
 */
router.get('/:id', optionalAuth, equipmentController.getEquipmentById);

/**
 * @route   POST /api/equipment
 * @desc    Créer un nouvel équipement
 * @access  Private (prestataire uniquement)
 */
router.post('/', authenticate, equipmentController.createEquipment);

/**
 * @route   PUT /api/equipment/:id
 * @desc    Mettre à jour un équipement
 * @access  Private (propriétaire uniquement)
 */
router.put('/:id', authenticate, equipmentController.updateEquipment);

/**
 * @route   DELETE /api/equipment/:id
 * @desc    Supprimer un équipement
 * @access  Private (propriétaire uniquement)
 */
router.delete('/:id', authenticate, equipmentController.deleteEquipment);

module.exports = router;
