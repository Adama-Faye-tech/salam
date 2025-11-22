import 'package:postgres/postgres.dart';
import '../config/database_config.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static DatabaseService? _instance;
  Connection? _connection;
  
  DatabaseService._();
  
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Connection> get connection async {
    if (_connection != null) {
      return _connection!;
    }
    
    _connection = await Connection.open(
      Endpoint(
        host: DatabaseConfig.host,
        database: DatabaseConfig.database,
        username: DatabaseConfig.username,
        password: DatabaseConfig.password,
        port: DatabaseConfig.port,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: Duration(seconds: DatabaseConfig.connectionTimeout),
      ),
    );
    
    return _connection!;
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      final conn = await connection;
      final result = await conn.execute(
        Sql.named(sql),
        parameters: parameters,
      );
      
      return result.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      debugPrint('Database query error: $e');
      rethrow;
    }
  }

  Future<int> execute(
    String sql, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      final conn = await connection;
      final result = await conn.execute(
        Sql.named(sql),
        parameters: parameters,
      );
      
      return result.affectedRows;
    } catch (e) {
      debugPrint('Database execute error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> queryOne(
    String sql, [
    Map<String, dynamic>? parameters,
  ]) async {
    final results = await query(sql, parameters);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  // MàƒÆ’à‚©thode helper pour les transactions
  Future<T> transaction<T>(Future<T> Function(Connection) action) async {
    final conn = await connection;
    
    try {
      await conn.execute('BEGIN');
      final result = await action(conn);
      await conn.execute('COMMIT');
      return result;
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }
}



