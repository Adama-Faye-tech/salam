import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../config/database_config.dart';
import 'database_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final _uuid = const Uuid();
  static const String _sessionKey = 'salam_session_token';
  static const String _userIdKey = 'salam_user_id';

  // Hachage du mot de passe avec bcrypt-like (SHA-256 + salt pour simplification)
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSalt() {
    return _uuid.v4().substring(0, 16);
  }

  // Inscription d'un nouvel utilisateur
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserType userType,
    String? location,
    String? bio,
  }) async {
    try {
      final db = DatabaseService.instance;

      // VàƒÆ’à‚©rifier si l'email existe dàƒÆ’à‚©jàƒÆ’à‚
      final existingUser = await db.queryOne(
        'SELECT id FROM users WHERE email = @email',
        {'email': email},
      );

      if (existingUser != null) {
        return {'success': false, 'message': 'Cet email est déjà utilisé'};
      }

      // GàƒÆ’à‚©nàƒÆ’à‚©rer un salt et hacher le mot de passe
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);
      final userId = 'user_${_uuid.v4()}';

      // InsàƒÆ’à‚©rer le nouvel utilisateur
      await db.execute(
        '''
        INSERT INTO users (
          id, name, email, phone, password, user_type, location, bio, created_at
        ) VALUES (
          @id, @name, @email, @phone, @password, @userType, @location, @bio, NOW()
        )
        ''',
        {
          'id': userId,
          'name': name,
          'email': email,
          'phone': phone,
          'password': '$salt:$hashedPassword',
          'userType': userType == UserType.farmer ? 'farmer' : 'provider',
          'location': location,
          'bio': bio,
        },
      );

      // CràƒÆ’à‚©er une session
      final session = await _createSession(userId);

      return {
        'success': true,
        'message': 'Inscription ràƒÆ’à‚©ussie',
        'userId': userId,
        'token': session['token'],
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      return {'success': false, 'message': 'Erreur lors de l\'inscription: $e'};
    }
  }

  // Connexion
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final db = DatabaseService.instance;

      // RàƒÆ’à‚©cupàƒÆ’à‚©rer l'utilisateur
      final user = await db.queryOne(
        'SELECT id, password FROM users WHERE email = @email',
        {'email': email},
      );

      if (user == null) {
        return {'success': false, 'message': 'Email ou mot de passe incorrect'};
      }

      // VàƒÆ’à‚©rifier le mot de passe
      final storedPassword = user['password'] as String;
      final parts = storedPassword.split(':');
      if (parts.length != 2) {
        return {
          'success': false,
          'message': 'Erreur de vérification du mot de passe',
        };
      }

      final salt = parts[0];
      final hashedPassword = parts[1];
      final computedHash = _hashPassword(password, salt);

      if (computedHash != hashedPassword) {
        return {'success': false, 'message': 'Email ou mot de passe incorrect'};
      }

      // CràƒÆ’à‚©er une session
      final userId = user['id'] as String;
      final session = await _createSession(userId);

      return {
        'success': true,
        'message': 'Connexion réussie',
        'userId': userId,
        'token': session['token'],
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Erreur lors de la connexion: $e'};
    }
  }

  // CràƒÆ’à‚©er une session
  Future<Map<String, dynamic>> _createSession(String userId) async {
    final db = DatabaseService.instance;
    final token = _uuid.v4();
    final sessionId = 'session_${_uuid.v4()}';
    final expiresAt = DateTime.now().add(
      Duration(days: DatabaseConfig.sessionDuration),
    );

    await db.execute(
      '''
      INSERT INTO sessions (id, user_id, token, expires_at, created_at, last_activity)
      VALUES (@id, @userId, @token, @expiresAt, NOW(), NOW())
      ''',
      {
        'id': sessionId,
        'userId': userId,
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
      },
    );

    // Sauvegarder localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, token);
    await prefs.setString(_userIdKey, userId);

    return {'token': token, 'sessionId': sessionId, 'expiresAt': expiresAt};
  }

  // VàƒÆ’à‚©rifier la session au dàƒÆ’à‚©marrage
  Future<UserModel?> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_sessionKey);

      if (token == null) {
        return null;
      }

      final db = DatabaseService.instance;

      // VàƒÆ’à‚©rifier si la session est valide
      final session = await db.queryOne(
        '''
        SELECT s.user_id, s.expires_at, u.* 
        FROM sessions s
        JOIN users u ON s.user_id = u.id
        WHERE s.token = @token AND s.expires_at > NOW()
        ''',
        {'token': token},
      );

      if (session == null) {
        // Session expiràƒÆ’à‚©e ou invalide
        await logout();
        return null;
      }

      // Mettre àƒÆ’à‚  jour last_activity
      await db.execute(
        'UPDATE sessions SET last_activity = NOW() WHERE token = @token',
        {'token': token},
      );

      // Convertir en UserModel
      return _userFromMap(session);
    } catch (e) {
      debugPrint('Check session error: $e');
      return null;
    }
  }

  // RàƒÆ’à‚©cupàƒÆ’à‚©rer un utilisateur par ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final db = DatabaseService.instance;
      final user = await db.queryOne('SELECT * FROM users WHERE id = @id', {
        'id': userId,
      });

      if (user == null) return null;
      return _userFromMap(user);
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  // DàƒÆ’à‚©connexion
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_sessionKey);

      if (token != null) {
        // Supprimer la session de la base de donnàƒÆ’à‚©es
        final db = DatabaseService.instance;
        await db.execute('DELETE FROM sessions WHERE token = @token', {
          'token': token,
        });
      }

      // Supprimer les donnàƒÆ’à‚©es locales
      await prefs.remove(_sessionKey);
      await prefs.remove(_userIdKey);
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // Mettre àƒÆ’à‚  jour le profil
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? location,
    String? bio,
    String? photo,
  }) async {
    try {
      final db = DatabaseService.instance;
      final updates = <String>[];
      final params = <String, dynamic>{'id': userId};

      if (name != null) {
        updates.add('name = @name');
        params['name'] = name;
      }
      if (phone != null) {
        updates.add('phone = @phone');
        params['phone'] = phone;
      }
      if (location != null) {
        updates.add('location = @location');
        params['location'] = location;
      }
      if (bio != null) {
        updates.add('bio = @bio');
        params['bio'] = bio;
      }
      if (photo != null) {
        updates.add('photo = @photo');
        params['photo'] = photo;
      }

      if (updates.isEmpty) {
        return {'success': false, 'message': 'Aucune modification à apporter'};
      }

      updates.add('updated_at = NOW()');

      await db.execute(
        'UPDATE users SET ${updates.join(', ')} WHERE id = @id',
        params,
      );

      return {'success': true, 'message': 'Profil mis à jour'};
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {'success': false, 'message': 'Erreur lors de la mise à jour: $e'};
    }
  }

  // Changer le mot de passe
  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final db = DatabaseService.instance;

      // VàƒÆ’à‚©rifier l'ancien mot de passe
      final user = await db.queryOne(
        'SELECT password FROM users WHERE id = @id',
        {'id': userId},
      );

      if (user == null) {
        return {'success': false, 'message': 'Utilisateur non trouvé'};
      }

      final storedPassword = user['password'] as String;
      final parts = storedPassword.split(':');
      final salt = parts[0];
      final hashedPassword = parts[1];
      final computedHash = _hashPassword(oldPassword, salt);

      if (computedHash != hashedPassword) {
        return {'success': false, 'message': 'Ancien mot de passe incorrect'};
      }

      // CràƒÆ’à‚©er un nouveau hash
      final newSalt = _generateSalt();
      final newHash = _hashPassword(newPassword, newSalt);

      await db.execute(
        'UPDATE users SET password = @password, updated_at = NOW() WHERE id = @id',
        {'id': userId, 'password': '$newSalt:$newHash'},
      );

      return {'success': true, 'message': 'Mot de passe modifié'};
    } catch (e) {
      debugPrint('Change password error: $e');
      return {
        'success': false,
        'message': 'Erreur lors du changement de mot de passe: $e',
      };
    }
  }

  // Convertir une map en UserModel
  UserModel _userFromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String? ?? '',
      address: map['location'] as String?,
      userType: (map['user_type'] as String) == 'farmer'
          ? UserType.farmer
          : UserType.provider,
      photoUrl: map['photo'] as String?,
      description: map['bio'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Nettoyer les sessions expiràƒÆ’à‚©es
  Future<int> cleanExpiredSessions() async {
    try {
      final db = DatabaseService.instance;
      return await db.execute('SELECT cleanup_expired_sessions()');
    } catch (e) {
      debugPrint('Clean sessions error: $e');
      return 0;
    }
  }
}
