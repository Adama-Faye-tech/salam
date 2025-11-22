import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/logger_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  UserProvider() {
    // L'initialisation et checkSession sont gérés par _AppInitializer dans main.dart
  }

  Future<void> checkSession() async {
    try {
      Log.d('Vérification de la session utilisateur', tag: 'UserProvider');
      final supabase = SupabaseService.instance;
      final user = supabase.currentUser;

      if (user != null) {
        // Récupérer les données du profil depuis Supabase avec timeout
        try {
          final profileData = await supabase.profiles
              .select()
              .eq('id', user.id)
              .single()
              .timeout(const Duration(seconds: 5));

          _currentUser = UserModel(
            id: user.id,
            name: profileData['name'] ?? user.userMetadata?['name'] ?? '',
            email: user.email ?? '',
            phone: profileData['phone'] ?? user.userMetadata?['phone'] ?? '',
            address: profileData['address'],
            location: profileData['location'] ?? user.userMetadata?['location'],
            photoUrl:
                profileData['photo_url'] ?? user.userMetadata?['photo_url'],
            description:
                profileData['description'] ?? user.userMetadata?['description'],
            userType: _parseUserType(
              profileData['user_type'] ?? user.userMetadata?['user_type'],
            ),
            createdAt: DateTime.parse(
              profileData['created_at'] ?? user.createdAt,
            ),
          );
        } catch (e) {
          // Si la table profiles n'existe pas, utiliser les métadonnées Auth
          debugPrint(
            '⚠️ Profil table non accessible, utilisation Auth metadata: $e',
          );
          _currentUser = UserModel(
            id: user.id,
            name: user.userMetadata?['name'] ?? '',
            email: user.email ?? '',
            phone: user.userMetadata?['phone'] ?? '',
            address: user.userMetadata?['address'],
            location: user.userMetadata?['location'],
            photoUrl: user.userMetadata?['photo_url'],
            description: user.userMetadata?['description'],
            userType: _parseUserType(user.userMetadata?['user_type']),
            createdAt: DateTime.parse(user.createdAt),
          );
        }

        Log.success(
          'Session valide pour ${_currentUser?.name}',
          tag: 'UserProvider',
        );
        notifyListeners();
      } else {
        Log.d('Aucune session active', tag: 'UserProvider');
        _currentUser = null;
        notifyListeners();
      }
    } catch (e) {
      Log.failure(
        'Erreur de vérification de session',
        tag: 'UserProvider',
        error: e,
      );
      _currentUser = null;
      notifyListeners();
      await SupabaseService.instance.signOut();
    }
  }

  UserType _parseUserType(dynamic userType) {
    if (userType == null) return UserType.farmer;
    final typeStr = userType.toString().toLowerCase();
    return UserType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr,
      orElse: () => UserType.farmer,
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = SupabaseService.instance;
      final response = await supabase.signIn(email: email, password: password);

      if (response.user != null) {
        // Charger le profil complet
        await checkSession();

        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'message': 'Connexion réussie',
          'user': _currentUser,
        };
      } else {
        _error = 'Échec de connexion';
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Échec de connexion'};
      }
    } catch (e) {
      String errorMessage = 'Erreur de connexion';

      // Analyser le type d'erreur pour donner un message plus clair
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid_credentials') ||
          errorString.contains('invalid login credentials')) {
        errorMessage =
            'Email ou mot de passe incorrect.\nSi vous n\'avez pas de compte, veuillez vous inscrire.';
      } else if (errorString.contains('network') ||
          errorString.contains('timeout')) {
        errorMessage =
            'Problème de connexion réseau. Vérifiez votre connexion internet.';
      } else if (errorString.contains('email not confirmed')) {
        errorMessage =
            'Veuillez confirmer votre email avant de vous connecter.';
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }

      _error = errorMessage;
      _isLoading = false;
      notifyListeners();

      Log.e('Erreur de connexion: $e', tag: 'UserProvider');
      return {'success': false, 'message': errorMessage};
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserType userType,
    String? location,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = SupabaseService.instance;

      // 1. Créer le compte Supabase Auth avec métadonnées
      final response = await supabase.signUp(
        email: email,
        password: password,
        name: name,
        metadata: {
          'phone': phone,
          'user_type': userType.name,
          'location': location,
        },
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // 2. Créer le profil dans la table profiles (si elle existe)
        try {
          await supabase.profiles.insert({
            'id': userId,
            'name': name,
            'phone': phone,
            'user_type': userType.name,
            'location': location,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('⚠️ Table profiles non accessible: $e');
        }

        // 3. Charger le profil complet
        await checkSession();

        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'message': 'Inscription réussie',
          'user': _currentUser,
        };
      } else {
        _error = 'Échec d\'inscription';
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Échec d\'inscription'};
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await SupabaseService.instance.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_currentUser == null) return;
    await checkSession();
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? location,
    String? photoUrl,
    String? description,
    String? userType,
  }) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'Utilisateur non connecté'};
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = SupabaseService.instance;
      final userId = supabase.currentUser?.id;

      if (userId == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Session expirée'};
      }

      // 1. Mettre à jour les métadonnées de l'utilisateur (nom, etc.)
      final userMetadata = <String, dynamic>{};
      if (name != null) userMetadata['name'] = name;
      if (phone != null) userMetadata['phone'] = phone;
      if (location != null) userMetadata['location'] = location;
      if (photoUrl != null) userMetadata['photo_url'] = photoUrl;
      if (description != null) userMetadata['description'] = description;
      if (userType != null) userMetadata['user_type'] = userType;

      if (userMetadata.isNotEmpty) {
        await supabase.updateUser(data: userMetadata);
      }

      // 2. Mettre à jour la table profiles si elle existe
      try {
        final profileData = <String, dynamic>{};
        if (name != null) profileData['name'] = name;
        if (phone != null) profileData['phone'] = phone;
        if (location != null) profileData['location'] = location;
        if (photoUrl != null) profileData['photo_url'] = photoUrl;
        if (description != null) profileData['description'] = description;
        if (userType != null) profileData['user_type'] = userType;
        profileData['updated_at'] = DateTime.now().toIso8601String();

        if (profileData.isNotEmpty) {
          await supabase.profiles
              .upsert({'id': userId, ...profileData})
              .select()
              .single();
        }
      } catch (e) {
        debugPrint('⚠️ Table profiles non accessible: $e');
      }

      // 3. Mettre à jour le modèle local
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: _currentUser!.email,
        phone: phone ?? _currentUser!.phone,
        address: _currentUser!.address,
        location: location ?? _currentUser!.location,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        description: description ?? _currentUser!.description,
        userType: userType != null
            ? UserType.values.firstWhere(
                (e) => e.name == userType,
                orElse: () => _currentUser!.userType,
              )
            : _currentUser!.userType,
        createdAt: _currentUser!.createdAt,
      );

      _isLoading = false;
      _error = null;
      notifyListeners();

      return {
        'success': true,
        'message': 'Profil mis à jour avec succès',
        'user': _currentUser,
      };
    } catch (e) {
      debugPrint('❌ Erreur mise à jour profil: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
