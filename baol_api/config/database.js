const { Pool } = require('pg');
require('dotenv').config();

// Configuration du pool de connexions PostgreSQL
// Normaliser et valider la configuration
const dbConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  // Forcer en string si défini pour éviter "client password must be a string"
  password: typeof process.env.DB_PASSWORD === 'undefined' ? undefined : String(process.env.DB_PASSWORD),
  max: 20, // Nombre maximum de connexions dans le pool
  idleTimeoutMillis: 30000, // Fermer les connexions inactives après 30s
  connectionTimeoutMillis: 5000, // Timeout de connexion
};

// Petit log de contrôle (sans secrets)
console.log(`🔌 PostgreSQL config -> host=${dbConfig.host} port=${dbConfig.port} db=${dbConfig.database} user=${dbConfig.user}`);

const pool = new Pool(dbConfig);

// Tester la connexion
pool.on('connect', () => {
  console.log('✓ Nouvelle connexion PostgreSQL établie');
});

pool.on('error', (err) => {
  console.error('✗ Erreur inattendue du pool PostgreSQL:', err);
  process.exit(-1);
});

// Fonction helper pour exécuter des requêtes
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Requête exécutée:', { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    console.error('Erreur de requête:', { text, error: error.message });
    throw error;
  }
};

// Fonction pour obtenir un client du pool (pour les transactions)
const getClient = async () => {
  const client = await pool.connect();
  const query = client.query;
  const release = client.release;

  // Timeout de 5 secondes pour eviter les fuites de connexions
  const timeout = setTimeout(() => {
    console.error('Client non relache apres 5 secondes!');
    console.error(new Error().stack);
  }, 5000);

  // Wrapper pour libérer le client automatiquement
  client.query = (...args) => {
    return query.apply(client, args);
  };

  client.release = () => {
    clearTimeout(timeout);
    client.query = query;
    client.release = release;
    return release.apply(client);
  };

  return client;
};

// Vérifier que toutes les tables existent
const ensureNotificationsTable = async () => {
  try {
    await query(
      `CREATE TABLE IF NOT EXISTS notifications (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        order_id VARCHAR(255),
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )`
    );
    await query(`CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id)`);
    await query(`CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read)`);
    console.log('✓ Table "notifications" vérifiée/créée');
  } catch (e) {
    console.error('✗ Erreur création table notifications:', e.message);
  }
};

const checkTables = async () => {
  try {
    const tables = ['users', 'equipment', 'chats', 'messages', 'favorites', 'orders', 'notifications'];
    
    for (const table of tables) {
      const result = await query(
        `SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = $1
        )`,
        [table]
      );
      
      if (!result.rows[0].exists) {
        console.warn(`⚠ Table "${table}" n'existe pas dans la base de données`);
        if (table === 'notifications') {
          await ensureNotificationsTable();
        }
      } else {
        console.log(`✓ Table "${table}" trouvée`);
      }
    }
  } catch (error) {
    console.error('Erreur lors de la vérification des tables:', error);
  }
};

module.exports = {
  pool,
  query,
  getClient,
  checkTables,
  ensureNotificationsTable,
};
