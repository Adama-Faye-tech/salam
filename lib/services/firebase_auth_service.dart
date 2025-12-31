import 'package:firebase_auth/firebase_auth.dart';

/// Service d'authentification Firebase
/// Remplace SupabaseService pour l'authentification
class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Utilisateur actuel
  static User? get currentUser => _auth.currentUser;

  // Stream des changements d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Vérifier si l'utilisateur est connecté
  static bool get isAuthenticated => currentUser != null;

  /// Inscription avec email et mot de passe
  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Connexion avec email et mot de passe
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Déconnexion
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Réinitialiser le mot de passe
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Mettre à jour le mot de passe
  static Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    await user.updatePassword(newPassword);
  }

  /// Mettre à jour l'email
  static Future<void> updateEmail(String newEmail) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  /// Envoyer un email de vérification
  static Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Supprimer le compte
  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    await user.delete();
  }

  /// Recharger les données de l'utilisateur
  static Future<void> reloadUser() async {
    await currentUser?.reload();
  }
}
