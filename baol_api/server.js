const express = require ('express');
const cors = require ('cors');
const path = require ('path');
require ('dotenv').config ();

const {checkTables} = require ('./config/database');

// Import des routes
const authRoutes = require ('./routes/auth.routes');
const equipmentRoutes = require ('./routes/equipment.routes');
const chatRoutes = require ('./routes/chat.routes');
const favoritesRoutes = require ('./routes/favorites.routes');
const ordersRoutes = require ('./routes/orders.routes');
const notificationsRoutes = require ('./routes/notifications.routes');
const uploadRoutes = require ('./routes/upload.routes');
const promoRoutes = require ('./routes/promo.routes');
const profileRoutes = require ('./routes/profile.routes');

// Initialisation de l'application Express
const app = express ();
const PORT = process.env.PORT || 3000;

// ==================== MIDDLEWARE ====================

// CORS - Autoriser toutes les origines en développement
app.use (
  cors ({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Parser JSON
app.use (express.json ());

// Parser URL-encoded
app.use (express.urlencoded ({extended: true}));

// Servir les fichiers statiques (uploads)
app.use ('/uploads', express.static (path.join (__dirname, 'uploads')));

// Logger des requêtes en développement
if (process.env.NODE_ENV === 'development') {
  app.use ((req, res, next) => {
    console.log (`[${new Date ().toISOString ()}] ${req.method} ${req.path}`);
    next ();
  });
}

// ==================== ROUTES ====================

// Route de santé
app.get ('/health', (req, res) => {
  res.status (200).json ({
    success: true,
    message: 'API SALAM is running',
    timestamp: new Date ().toISOString (),
    environment: process.env.NODE_ENV,
  });
});

// Routes de l'API
app.use ('/api/auth', authRoutes);
app.use ('/api/equipment', equipmentRoutes);
app.use ('/api/chat', chatRoutes);
app.use ('/api/favorites', favoritesRoutes);
app.use ('/api/orders', ordersRoutes);
app.use ('/api/notifications', notificationsRoutes);
app.use ('/api/upload', uploadRoutes);
app.use ('/api/promo', promoRoutes);
app.use ('/api/profile', profileRoutes);

// Route 404
app.use ((req, res) => {
  res.status (404).json ({
    success: false,
    message: 'Route non trouvée',
    path: req.path,
  });
});

// ==================== GESTION DES ERREURS ====================

// Gestionnaire d'erreurs global
app.use ((err, req, res, next) => {
  console.error ('Erreur non gérée:', err);

  res.status (err.status || 500).json ({
    success: false,
    message: err.message || 'Erreur interne du serveur',
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });
});

// ==================== DÉMARRAGE DU SERVEUR ====================

const startServer = async () => {
  try {
    // Vérifier la connexion à la base de données
    console.log ('📊 Vérification de la base de données...');
    await checkTables ();

    // Démarrer le serveur
    app.listen (PORT, '0.0.0.0', () => {
      console.log ('');
      console.log ('========================================');
      console.log (`🚀 Serveur démarré avec succès !`);
      console.log (`📍 URL locale: http://localhost:${PORT}`);
      console.log (`📱 URL réseau: http://192.168.1.23:${PORT}`);
      console.log (
        `🌍 Environnement: ${process.env.NODE_ENV || 'development'}`
      );
      console.log ('========================================');
      console.log ('');
      console.log ('📋 Endpoints disponibles:');
      console.log (`   GET    /health`);
      console.log (`   POST   /api/auth/register`);
      console.log (`   POST   /api/auth/login`);
      console.log (`   GET    /api/auth/me`);
      console.log (`   PUT    /api/auth/update-profile`);
      console.log (`   GET    /api/equipment`);
      console.log (`   POST   /api/equipment`);
      console.log (`   GET    /api/chat/conversations`);
      console.log (`   POST   /api/chat/create`);
      console.log (`   GET    /api/favorites`);
      console.log (`   GET    /api/orders`);
      console.log ('');
      console.log ('✅ Prêt à recevoir des requêtes !');
    });
  } catch (error) {
    console.error ('❌ Erreur lors du démarrage du serveur:', error);
    process.exit (1);
  }
};

// Démarrer le serveur
startServer ();

// Gestion de l'arrêt gracieux
process.on ('SIGINT', () => {
  console.log ('\n⚠ Arrêt du serveur...');
  process.exit (0);
});

process.on ('SIGTERM', () => {
  console.log ('\n⚠ Arrêt du serveur...');
  process.exit (0);
});

module.exports = app;
