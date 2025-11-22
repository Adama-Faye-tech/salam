const express = require('express');
const router = express.Router();
const ordersController = require('../controllers/orders.controller');
const { authenticate } = require('../middleware/auth');

/**
 * @route   GET /api/orders
 * @desc    Obtenir toutes les commandes de l'utilisateur
 * @access  Private
 */
router.get('/', authenticate, ordersController.getUserOrders);

/**
 * @route   GET /api/orders/:id
 * @desc    Obtenir les détails d'une commande
 * @access  Private
 */
router.get('/:id', authenticate, ordersController.getOrderById);

/**
 * @route   POST /api/orders
 * @desc    Créer une nouvelle commande
 * @access  Private
 */
router.post('/', authenticate, ordersController.createOrder);

/**
 * @route   PUT /api/orders/:id/status
 * @desc    Mettre à jour le statut d'une commande
 * @access  Private
 */
router.put('/:id/status', authenticate, ordersController.updateOrderStatus);

/**
 * @route   DELETE /api/orders/:id
 * @desc    Annuler une commande
 * @access  Private
 */
router.delete('/:id', authenticate, ordersController.cancelOrder);

module.exports = router;
