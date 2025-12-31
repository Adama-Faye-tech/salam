import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/logger_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  // Backwards-compatible alias used in some screens/providers
  UserModel? get user => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  UserProvider() {
    // L'initialisation et checkSession sont gérés par _AppInitializer dans main.dart
  }

  Future<void> checkSession() async {
    try {
      Log.d('Vérification de la session utilisateur', tag: 'UserProvider');
      final user = FirebaseAuthService.currentUser;

      if (user != null) {
        // Récupérer les données du profil depuis Firestore
        try {
          final profileDoc = await FirestoreService.users.doc(user.uid).get();

          if (profileDoc.exists) {
            final profileData = profileDoc.data() as Map<String, dynamic>;

            _currentUser = UserModel(
              id: user.uid,
              name: profileData['name'] ?? user.displayName ?? '',
              email: user.email ?? '',
              phone: profileData['phone'] ?? '',
              address: profileData['address'],
              location: profileData['location'],
              photoUrl: profileData['photo_url'] ?? user.photoURL,
              description: profileData['description'],
              userType: _parseUserType(profileData['user_type']),
              createdAt:
                  FirestoreService.timestampToDateTime(
                    profileData['created_at'],
                  ) ??
                  DateTime.now(),
            );
          } else {
            // Document de profil n'existe pas encore, créer à partir des données Auth
            _currentUser = UserModel(
              id: user.uid,
              name: user.displayName ?? '',
              email: user.email ?? '',
              phone: '',
              address: null,
              location: null,
              photoUrl: user.photoURL,
              description: null,
              userType: UserType.farmer,
              createdAt: user.metadata.creationTime ?? DateTime.now(),
            );
          }
        } catch (e) {
          // Si erreur Firestore, utiliser les données Auth uniquement
          debugPrint('⚠️ Profil Firestore non accessible: $e');
          _currentUser = UserModel(
            id: user.uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
            phone: '',
            address: null,
            location: null,
            photoUrl: user.photoURL,
            description: null,
            userType: UserType.farmer,
            createdAt: user.metadata.creationTime ?? DateTime.now(),
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
      await FirebaseAuthService.signOut();
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
      final userCredential = await FirebaseAuthService.signIn(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
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

      // Analyser le type d'erreur Firebase
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid-credential') ||
          errorString.contains('wrong-password') ||
          errorString.contains('user-not-found')) {
        errorMessage =
            'Email ou mot de passe incorrect.\nSi vous n\'avez pas de compte, veuillez vous inscrire.';
      } else if (errorString.contains('network') ||
          errorString.contains('timeout')) {
        errorMessage =
            'Problème de connexion réseau. Vérifiez votre connexion internet.';
      } else if (errorString.contains('too-many-requests')) {
        errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard.';
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
      // 1. Créer le compte Firebase Auth
      final userCredential = await FirebaseAuthService.signUp(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        debugPrint('✅ Compte créé avec succès, ID: $userId');

        // 2. Créer le document de profil dans Firestore
        try {
          await FirestoreService.users.doc(userId).set({
            'id': userId,
            'name': name,
            'email': email,
            'phone': phone,
            'user_type': userType.name,
            'location': location,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Profil créé dans Firestore');
        } catch (e) {
          debugPrint('⚠️ Erreur création profil Firestore: $e');
        }

        // 3. Créer l'utilisateur en mémoire
        _currentUser = UserModel(
          id: userId,
          name: name,
          email: email,
          phone: phone,
          address: null,
          location: location,
          photoUrl: null,
          description: null,
          userType: userType,
          createdAt: DateTime.now(),
        );

        debugPrint('✅ Utilisateur créé en mémoire: ${_currentUser?.name}');

        // 4. Charger les vraies données depuis Firestore
        await checkSession();

        _isLoading = false;
        notifyListeners();

        // Vérifier si l'email est vérifié
        if (!userCredential.user!.emailVerified) {
          try {
            await FirebaseAuthService.sendEmailVerification();
          } catch (e) {
            debugPrint('⚠️ Erreur envoi email de vérification: $e');
          }

          return {
            'success': true,
            'requiresConfirmation': true,
            'message':
                '✅ Compte créé avec succès !\n\n'
                '📧 Vérifiez votre email pour confirmer votre compte.\n\n'
                '⚠️ Vous devez confirmer votre email pour accéder à toutes les fonctionnalités.',
          };
        }

        return {
          'success': true,
          'message': 'Inscription réussie ! Bienvenue sur SALAM.',
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
      await FirebaseAuthService.signOut();
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
      final userId = FirebaseAuthService.currentUser?.uid;

      if (userId == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Session expirée'};
      }

      // Préparer les données à mettre à jour
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (location != null) updateData['location'] = location;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;
      if (description != null) updateData['description'] = description;
      if (userType != null) updateData['user_type'] = userType;
      updateData['updated_at'] = FieldValue.serverTimestamp();

      if (updateData.isNotEmpty) {
        await FirestoreService.users.doc(userId).update(updateData);
      }

      // Mettre à jour le modèle local
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

  Future<void> updatePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await FirebaseAuthService.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors de la mise à jour du mot de passe: $e');
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = FirebaseAuthService.currentUser?.uid;
      if (userId != null) {
        // Supprimer le document Firestore
        await FirestoreService.users.doc(userId).delete();
      }

      // Supprimer le compte Firebase Auth
      await FirebaseAuthService.deleteAccount();

      // Déconnexion locale
      await logout();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
