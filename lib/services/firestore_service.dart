import 'package:cloud_firestore/cloud_firestore.dart';

/// Service Firestore pour l'accès aux collections
/// Remplace l'accès aux tables Supabase
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections principales
  static CollectionReference get users => _db.collection('users');
  static CollectionReference get equipment => _db.collection('equipment');
  static CollectionReference get chats => _db.collection('chats');
  static CollectionReference get orders => _db.collection('orders');
  static CollectionReference get favorites => _db.collection('favorites');
  static CollectionReference get notifications => _db.collection('notifications');

  // Sous-collections
  static CollectionReference messages(String chatId) =>
      chats.doc(chatId).collection('messages');

  /// Helper pour créer ou mettre à jour un document
  static Future<void> setDocument({
    required CollectionReference collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await collection.doc(docId).set(data, SetOptions(merge: merge));
  }

  /// Helper pour récupérer un document
  static Future<DocumentSnapshot> getDocument({
    required CollectionReference collection,
    required String docId,
  }) async {
    return await collection.doc(docId).get();
  }

  /// Helper pour supprimer un document
  static Future<void> deleteDocument({
    required CollectionReference collection,
    required String docId,
  }) async {
    await collection.doc(docId).delete();
  }

  /// Helper pour les timestamps
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Convertir Timestamp Firestore en DateTime
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }
}
