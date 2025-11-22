const jwt = require('jsonwebtoken');
require('dotenv').config();

/**
 * Middleware d'authentification JWT
 * Vérifie la présence et la validité du token JWT dans les headers
 */
const authenticate = async (req, res, next) => {
  try {
    // Récupérer le token depuis le header Authorization
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: 'Token d\'authentification manquant',
      });
    }

    // Format attendu: "Bearer <token>"
    const parts = authHeader.split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return res.status(401).json({
        success: false,
        message: 'Format du token invalide. Format attendu: Bearer <token>',
      });
    }

    const token = parts[1];

    // Vérifier et décoder le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Ajouter les informations de l'utilisateur à la requête
    req.user = {
      id: decoded.userId,
      email: decoded.email,
      name: decoded.name,
      role: decoded.role,
    };

    // Passer au middleware suivant
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expiré',
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Token invalide',
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification du token',
      error: error.message,
    });
  }
};

/**
 * Middleware optionnel - n'échoue pas si le token est absent
 * Utile pour les routes qui peuvent être publiques ou authentifiées
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      req.user = null;
      return next();
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      req.user = null;
      return next();
    }

    const token = parts[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = {
      id: decoded.userId,
      email: decoded.email,
      name: decoded.name,
      role: decoded.role,
    };

    next();
  } catch (error) {
    req.user = null;
    next();
  }
};

/**
 * Middleware pour vérifier le rôle de l'utilisateur
 * @param {string[]} roles - Liste des rôles autorisés
 */
const checkRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentification requise',
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Rôle insuffisant.',
        requiredRoles: roles,
        userRole: req.user.role,
      });
    }

    next();
  };
};

/**
 * Générer un token JWT
 * @param {object} payload - Données à encoder dans le token
 * @returns {string} Token JWT
 */
const generateToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  });
};

/**
 * Vérifier un token JWT
 * @param {string} token - Token à vérifier
 * @returns {object} Payload décodé
 */
const verifyToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

module.exports = {
  authenticate,
  optionalAuth,
  checkRole,
  generateToken,
  verifyToken,
};
