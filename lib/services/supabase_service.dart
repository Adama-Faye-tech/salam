import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service singleton pour gérer la connexion Supabase
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseService._();

  // Configuration Supabase (clé en dur temporaire — idéalement depuis .env / secrets)
  static const String _supabaseUrl = 'https://bfmnqkmdjerzbgafdclo.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmbW5xa21kamVyemJnYWZkY2xvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0MjQzNzgsImV4cCI6MjA3OTAwMDM3OH0.Eh88A1zIVHx_SFwsIy8az8NoHjVLK8DovU7sZA-m-Z8';

  // Client de secours (utilisé si Supabase Flutter n'est pas initialisé)
  static SupabaseClient? _fallbackClient;

  // StreamController pour notifier quand l'initialisation est terminée
  static final _initializationController = StreamController<bool>.broadcast();

  /// Stream qui émet `true` quand Supabase Flutter est complètement initialisé
  static Stream<bool> get onInitializationComplete =>
      _initializationController.stream;

  /// Client Supabase
  SupabaseClient get client {
    try {
      // Normal path: Supabase Flutter a été initialisé
      return Supabase.instance.client;
    } catch (_) {
      // Si l'initialisation Flutter n'est pas encore faite, retourner
      // un client Supabase léger construit directement (non Flutter).
      _fallbackClient ??= SupabaseClient(_supabaseUrl, _supabaseAnonKey);
      return _fallbackClient!;
    }
  }

  /// Utilisateur actuel
  User? get currentUser => client.auth.currentUser;

  /// Stream des changements d'authentification
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Initialiser Supabase
  static Future<void> initialize() async {
    // Tenter d'initialiser Supabase Flutter (utile pour features Flutter-specific)
    // Mais ne pas laisser cette initialisation bloquer l'application :
    // en cas d'échec/timeout on loggue et on continue. Les appels au client
    // utiliseront un client de secours construit directement si besoin.
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 10,
          timeout: Duration(seconds: 10),
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          // Timeout : on ne propage pas l'erreur vers le caller
          throw TimeoutException('Timeout lors de l\'initialisation Supabase');
        },
      );
      // Si on arrive ici, Supabase Flutter est prêt et on peut nettoyer le fallback
      _fallbackClient = null;
      // Petite info pour debug
      // ignore: avoid_print
      print('✅ Supabase Flutter initialisé avec succès');

      // Notifier que l'initialisation est complète
      _initializationController.add(true);
    } catch (e, st) {
      // Ne pas faire échouer l'application si Supabase est lent ou inaccessible.
      // On loggue l'erreur et on continue : le getter `client` fournit
      // un client de secours qui permet au reste de l'app de continuer.
      // ignore: avoid_print
      print('⚠️ Supabase initialisation failed (non blocking): $e');
      // Optionnel: conserver une trace plus détaillée si nécessaire
      // ignore: avoid_print
      print(st);

      // Notifier quand même l'initialisation pour débloquer l'app
      _initializationController.add(true);
    }
  }

  // ==========================================
  // AUTHENTIFICATION
  // ==========================================

  /// Inscription avec email et mot de passe
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    Map<String, dynamic>? metadata,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, ...?metadata},
    );
  }

  /// Connexion avec email et mot de passe
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Déconnexion
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    // Configurer le lien de redirection pour pointer vers l'app
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.salamagri.salam://reset-password',
    );
  }

  /// Mettre à jour le profil utilisateur
  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.updateUser(
      UserAttributes(email: email, password: password, data: data),
    );
  }

  // ==========================================
  // BASE DE DONNÉES
  // ==========================================

  /// Obtenir une référence à une table
  SupabaseQueryBuilder table(String tableName) => client.from(tableName);

  /// Profils
  SupabaseQueryBuilder get profiles => table('profiles');

  /// Équipements
  SupabaseQueryBuilder get equipment => table('equipment');

  /// Chats
  SupabaseQueryBuilder get chats => table('chats');

  /// Messages
  SupabaseQueryBuilder get messages => table('messages');

  /// Favoris
  SupabaseQueryBuilder get favorites => table('favorites');

  /// Commandes/Réservations
  SupabaseQueryBuilder get orders => table('orders');

  /// Notifications
  SupabaseQueryBuilder get notifications => table('notifications');

  // ==========================================
  // STORAGE
  // ==========================================

  /// Uploader un fichier
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    await client.storage
        .from(bucket)
        .upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Obtenir l'URL publique d'un fichier
  String getPublicUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Supprimer un fichier
  Future<void> deleteFile(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  // ==========================================
  // REALTIME
  // ==========================================

  /// S'abonner aux changements d'une table
  RealtimeChannel subscribeToTable(
    String tableName, {
    void Function(PostgresChangePayload)? onInsert,
    void Function(PostgresChangePayload)? onUpdate,
    void Function(PostgresChangePayload)? onDelete,
  }) {
    final channel = client.channel('public:$tableName');

    if (onInsert != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: tableName,
        callback: onInsert,
      );
    }

    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: tableName,
        callback: onUpdate,
      );
    }

    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: tableName,
        callback: onDelete,
      );
    }

    channel.subscribe();
    return channel;
  }

  /// Se désabonner d'un channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await channel.unsubscribe();
  }
}
