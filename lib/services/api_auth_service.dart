import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

/// Service d'authentification utilisant l'API REST
class ApiAuthService {
  static final ApiAuthService instance = ApiAuthService._();
  ApiAuthService._();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Inscription d'un nouvel utilisateur
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserType userType,
    String? location,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': userType == UserType.farmer ? 'client' : 'provider',
          'address': location,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        await _saveAuthData(data['data']['token'], data['data']['user']);

        return {
          'success': true,
          'message': data['message'] ?? 'Inscription réussie',
          'user': _parseUser(data['data']['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'inscription',
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur inscription: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// Connexion d'un utilisateur
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveAuthData(data['data']['token'], data['data']['user']);

        return {
          'success': true,
          'message': data['message'] ?? 'Connexion réussie',
          'user': _parseUser(data['data']['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Identifiants invalides',
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur connexion: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Récupérer l'utilisateur connecté
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson == null) return null;

      final userData = jsonDecode(userJson);
      return _parseUser(userData);
    } catch (e) {
      debugPrint('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }

  /// Récupérer le token d'authentification
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Sauvegarder les données d'authentification
  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Parser les données utilisateur
  UserModel _parseUser(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'].toString(),
      email: data['email'],
      name: data['name'],
      phone: data['phone'],
      address: data['address'],
      userType: data['role'] == 'provider'
          ? UserType.provider
          : UserType.farmer,
      photoUrl: data['photo_url'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  /// Récupérer le profil complet de l'utilisateur
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/me');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveAuthData(token, data['data']['user']);

        return {'success': true, 'user': _parseUser(data['data']['user'])};
      } else {
        return {
          'success': false,
          'message':
              data['message'] ?? 'Erreur lors de la récupération du profil',
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération profil: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// Mettre à jour le profil
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? location,
    String? photoUrl,
    String? description,
    String? userType,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/update-profile');

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (location != null) body['location'] = location;
      if (photoUrl != null) body['photoUrl'] = photoUrl;
      if (description != null) body['description'] = description;
      if (userType != null) body['userType'] = userType;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.body.isEmpty || response.body.trim().isEmpty) {
        if (response.statusCode == 200 || response.statusCode == 204) {
          final profileResult = await getProfile();
          if (profileResult['success'] == true) {
            return {
              'success': true,
              'message': 'Profil mis à jour avec succès',
              'user': profileResult['user'],
            };
          }
        }
        return {
          'success': false,
          'message': 'Erreur lors de la mise à jour du profil',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Cas 1: Format {success: true, message: "...", data: {user: {...}}}
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['user'] != null) {
          await _saveAuthData(token, data['data']['user']);

          return {
            'success': true,
            'message': data['message'] ?? 'Profil mis à jour',
            'user': _parseUser(data['data']['user']),
          };
        }

        // Cas 2: Format {success: true, user: {...}}
        if (data['success'] == true && data['user'] != null) {
          await _saveAuthData(token, data['user']);

          return {
            'success': true,
            'message': data['message'] ?? 'Profil mis à jour',
            'user': _parseUser(data['user']),
          };
        }

        // Cas 3: Réponse succès mais sans user, on récupère le profil
        if (data['success'] == true) {
          final profileResult = await getProfile();
          if (profileResult['success'] == true) {
            return {
              'success': true,
              'message': data['message'] ?? 'Profil mis à jour',
              'user': profileResult['user'],
            };
          }
        }
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la mise à jour',
      };
    } catch (e) {
      debugPrint('❌ Erreur mise à jour profil: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }
}
