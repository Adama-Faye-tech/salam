const express = require ('express');
const router = express.Router ();
const authController = require ('../controllers/auth.controller');
const {authenticate} = require ('../middleware/auth');

/**
 * @route   POST /api/auth/register
 * @desc    Créer un nouveau compte utilisateur
 * @access  Public
 */
router.post ('/register', authController.register);

/**
 * @route   POST /api/auth/login
 * @desc    Se connecter avec email et mot de passe
 * @access  Public
 */
router.post ('/login', authController.login);

/**
 * @route   GET /api/auth/me
 * @desc    Obtenir le profil de l'utilisateur connecté
 * @access  Private (nécessite JWT)
 */
router.get ('/me', authenticate, authController.getProfile);

/**
 * @route   PUT /api/auth/update-profile
 * @desc    Mettre à jour le profil de l'utilisateur
 * @access  Private (nécessite JWT)
 */
router.put ('/update-profile', authenticate, authController.updateProfile);

/**
 * @route   PUT /api/auth/change-password
 * @desc    Changer le mot de passe
 * @access  Private (nécessite JWT)
 */
router.put ('/change-password', authenticate, authController.changePassword);

/**
 * @route   DELETE /api/auth/delete-account
 * @desc    Supprimer le compte utilisateur
 * @access  Private (nécessite JWT)
 */
router.delete ('/delete-account', authenticate, authController.deleteAccount);

module.exports = router;
