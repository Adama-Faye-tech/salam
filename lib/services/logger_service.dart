import 'package:flutter/foundation.dart';

/// Service de logging centralisé pour l'application
/// Permet de gérer les logs avec différents niveaux de gravité
/// et de les activer/désactiver selon l'environnement
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  
  factory LoggerService() => _instance;
  
  LoggerService._internal();

  // Configuration du niveau de log minimum à  afficher
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;
  
  // Active/désactive les logs complètement
  static bool _enabled = true;

  /// Configure le niveau minimum de log à  afficher
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Active ou désactive les logs
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Log de niveau DEBUG (détails techniques, développement)
  static void debug(String message, {String? tag, dynamic data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log de niveau INFO (informations générales)
  static void info(String message, {String? tag, dynamic data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log de niveau WARNING (avertissements)
  static void warning(String message, {String? tag, dynamic data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log de niveau ERROR (erreurs)
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, data: error);
    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Méthode interne pour logger les messages
  static void _log(LogLevel level, String message, {String? tag, dynamic data}) {
    if (!_enabled || level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.emoji + level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag]' : '';
    final dataStr = data != null ? '\n  Data: $data' : '';

    final logMessage = '$timestamp $levelStr $tagStr $message$dataStr';

    // Utilise debugPrint pour respecter les limites de la console Flutter
    debugPrint(logMessage);
  }

  /// Log de succès d'une opération
  static void success(String message, {String? tag}) {
    info('œ… $message', tag: tag);
  }

  /// Log d'échec d'une opération
  static void failure(String message, {String? tag, dynamic error}) {
    error('Œ $message', tag: tag, error: error);
  }

  /// Log pour les requêtes HTTP
  static void httpRequest(String method, String url, {String? tag}) {
    debug('†’ $method $url', tag: tag ?? 'HTTP');
  }

  /// Log pour les réponses HTTP
  static void httpResponse(int statusCode, String url, {String? tag, dynamic data}) {
    if (statusCode >= 200 && statusCode < 300) {
      debug('† $statusCode $url', tag: tag ?? 'HTTP', data: data);
    } else {
      warning('† $statusCode $url', tag: tag ?? 'HTTP', data: data);
    }
  }
}

/// Niveaux de gravité des logs
enum LogLevel {
  debug('ðŸ”'),
  info('„¹ï¸'),
  warning('š ï¸'),
  error('Œ');

  final String emoji;
  const LogLevel(this.emoji);
}

/// Alias pratiques pour un accès rapide
class Log {
  static void d(String message, {String? tag, dynamic data}) =>
      LoggerService.debug(message, tag: tag, data: data);
  
  static void i(String message, {String? tag, dynamic data}) =>
      LoggerService.info(message, tag: tag, data: data);
  
  static void w(String message, {String? tag, dynamic data}) =>
      LoggerService.warning(message, tag: tag, data: data);
  
  static void e(String message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      LoggerService.error(message, tag: tag, error: error, stackTrace: stackTrace);

  static void success(String message, {String? tag}) =>
      LoggerService.success(message, tag: tag);

  static void failure(String message, {String? tag, dynamic error}) =>
      LoggerService.failure(message, tag: tag, error: error);
}


