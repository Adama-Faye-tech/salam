// Test de connexion à PostgreSQL
require('dotenv').config();
const { Pool } = require('pg');

console.log('🔍 Test de connexion PostgreSQL...\n');

console.log('Configuration:');
console.log(`  Host: ${process.env.DB_HOST}`);
console.log(`  Port: ${process.env.DB_PORT}`);
console.log(`  Database: ${process.env.DB_NAME}`);
console.log(`  User: ${process.env.DB_USER}`);
console.log(`  Password: ${process.env.DB_PASSWORD ? '***SET***' : '***NOT SET***'}`);
console.log(`  Password type: ${typeof process.env.DB_PASSWORD}`);
console.log(`  Password length: ${process.env.DB_PASSWORD ? process.env.DB_PASSWORD.length : 0}`);
console.log('');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: String(process.env.DB_PASSWORD), // Forcer conversion en string
});

async function testConnection() {
  try {
    console.log('📡 Tentative de connexion...');
    const client = await pool.connect();
    console.log('✅ Connexion réussie !\n');

    // Test query
    const result = await client.query('SELECT NOW()');
    console.log('⏰ Date serveur:', result.rows[0].now);
    console.log('');

    // Lister les tables
    const tables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log('📊 Tables trouvées:');
    tables.rows.forEach((row, i) => {
      console.log(`  ${i + 1}. ${row.table_name}`);
    });
    console.log('');

    // Vérifier table notifications
    const notifCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications'
      )
    `);

    if (notifCheck.rows[0].exists) {
      console.log('✅ Table notifications existe');
      
      // Compter les notifications
      const count = await client.query('SELECT COUNT(*) FROM notifications');
      console.log(`   Notifications: ${count.rows[0].count}`);
    } else {
      console.log('⚠️  Table notifications n\'existe pas');
      console.log('   → Exécutez setup_notifications.sql');
    }

    client.release();
    await pool.end();
    
    console.log('\n✅ Test terminé avec succès !');
    process.exit(0);

  } catch (error) {
    console.error('\n❌ Erreur de connexion:');
    console.error('Message:', error.message);
    console.error('Code:', error.code);
    console.error('');
    console.error('💡 Solutions possibles:');
    console.error('1. Vérifiez que PostgreSQL est démarré');
    console.error('2. Vérifiez le mot de passe dans .env');
    console.error('3. Vérifiez que la base baol_db existe');
    console.error('4. Testez avec: psql -U postgres -d baol_db');
    await pool.end();
    process.exit(1);
  }
}

testConnection();
