class DatabaseConfig {
  // Configuration PostgreSQL
  static const String host = 'localhost';
  static const int port = 5432;
  static const String database = 'same_db';
  static const String username = 'postgres';
  static const String password = 'adama';
  
  // Durée de validité des sessions (en jours)
  static const int sessionDuration = 30;
  
  // Pool de connexions
  static const int maxConnections = 10;
  static const int connectionTimeout = 30; // secondes
}



