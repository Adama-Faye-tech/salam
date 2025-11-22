import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';

/// Service API pour communiquer avec le backend Node.js/Express
class ApiService {
  String get _baseUrl => ApiConfig.baseUrl;
  static const String _tokenKey = 'jwt_token';

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('Erreur token: $e');
      return null;
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('Erreur sauvegarde: $e');
    }
  }

  Future<void> _removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      debugPrint('Erreur suppression: $e');
    }
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
    String role = 'client',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
          'role': role,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        if (data['token'] != null) await _saveToken(data['token']);
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('Erreur inscription: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({'email': email, 'password': password}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (data['token'] != null) await _saveToken(data['token']);
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('Erreur connexion: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  Future<void> logout() async => await _removeToken();
  Future<bool> isLoggedIn() async => (await _getToken()) != null;

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['user'];
      }
      return null;
    } catch (e) {
      debugPrint('Erreur user: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getEquipments({
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double? maxDistance,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (maxDistance != null) {
        queryParams['maxDistance'] = maxDistance.toString();
      }

      final uri = Uri.parse(
        '$_baseUrl/equipment',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['equipments'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur equipments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getEquipmentById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/equipment/$id'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['equipment'];
      }
      return null;
    } catch (e) {
      debugPrint('Erreur equipment: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMyEquipments() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/equipment/my'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['equipments'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur my equipments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createEquipment({
    required String title,
    required String category,
    required double dailyRate,
    String? description,
    List<String>? images,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/equipment'),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'category': category,
          'description': description,
          'daily_rate': dailyRate,
          'images': images,
          'available': true,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'equipment': data['equipment']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('Erreur create equipment: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  Future<Map<String, dynamic>> updateEquipment({
    required int id,
    String? title,
    String? category,
    String? description,
    double? dailyRate,
    bool? available,
    List<String>? images,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (category != null) body['category'] = category;
      if (description != null) body['description'] = description;
      if (dailyRate != null) body['daily_rate'] = dailyRate;
      if (available != null) body['available'] = available;
      if (images != null) body['images'] = images;

      final response = await http.put(
        Uri.parse('$_baseUrl/equipment/$id'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'equipment': data['equipment']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('Erreur update equipment: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  Future<bool> deleteEquipment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/equipment/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur delete equipment: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required int equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    String? deliveryAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: await _getHeaders(),
        body: json.encode({
          'equipment_id': equipmentId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'delivery_address': deliveryAddress,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'order': data['order']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('Erreur create order: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/my'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur my orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrderById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/$id'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['order'];
      }
      return null;
    } catch (e) {
      debugPrint('Erreur order: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/orders/$orderId/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'order': data['order']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('Erreur update status: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/favorites'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['favorites'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur favorites: $e');
      return [];
    }
  }

  Future<bool> addFavorite(int equipmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/favorites'),
        headers: await _getHeaders(),
        body: json.encode({'equipment_id': equipmentId}),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Erreur add favorite: $e');
      return false;
    }
  }

  Future<bool> removeFavorite(int equipmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/favorites/$equipmentId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur remove favorite: $e');
      return false;
    }
  }

  Future<bool> isFavorite(int equipmentId) async {
    final favorites = await getFavorites();
    return favorites.any((fav) => fav['equipment_id'] == equipmentId);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur notifications: $e');
      return [];
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur mark notification: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur mark all notifications: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur delete notification: $e');
      return false;
    }
  }

  Future<bool> deleteAllNotifications() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/read/all'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur delete all notifications: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['conversations'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur conversations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['messages'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur messages: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String content,
    String? attachmentUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/messages'),
        headers: await _getHeaders(),
        body: json.encode({
          'conversation_id': conversationId,
          'content': content,
          'attachment_url': attachmentUrl,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('Erreur send message: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  Future<Map<String, dynamic>> getOrCreateConversation(int otherUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/conversations'),
        headers: await _getHeaders(),
        body: json.encode({'other_user_id': otherUserId}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'conversation': data['conversation']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('Erreur conversation: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  // ==================== UPLOAD ====================

  /// Upload une image vers le serveur
  Future<String?> uploadImage(String filePath, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/image'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = json.decode(responseData);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['file']['url'] as String;
      }
      debugPrint('Erreur upload image: ${data['message']}');
      return null;
    } catch (e) {
      debugPrint('Erreur upload image: $e');
      return null;
    }
  }

  /// Upload un fichier audio vers le serveur
  Future<String?> uploadAudio(String filePath, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/audio'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = json.decode(responseData);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['file']['url'] as String;
      }
      debugPrint('Erreur upload audio: ${data['message']}');
      return null;
    } catch (e) {
      debugPrint('Erreur upload audio: $e');
      return null;
    }
  }

  /// Upload un document vers le serveur
  Future<String?> uploadDocument(String filePath, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/document'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = json.decode(responseData);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['file']['url'] as String;
      }
      debugPrint('Erreur upload document: ${data['message']}');
      return null;
    } catch (e) {
      debugPrint('Erreur upload document: $e');
      return null;
    }
  }

  // ==================== ORDERS (Extended) ====================

  /// Récupérer les commandes où l'utilisateur est prestataire
  Future<List<Map<String, dynamic>>> getProviderOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders?provider=true'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      }
      debugPrint('Erreur récupération commandes prestataire');
      return [];
    } catch (e) {
      debugPrint('Erreur récupération commandes prestataire: $e');
      return [];
    }
  }

  // ==================== PROMO ====================

  /// Vérifier un code promo
  Future<Map<String, dynamic>> verifyPromoCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/promo/verify'),
        headers: await _getHeaders(),
        body: json.encode({'code': code}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'code': data['promo']['code'],
          'discount': data['promo']['discount'],
          'type': data['promo']['type'],
          'description': data['promo']['description'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Code promo invalide',
      };
    } catch (e) {
      debugPrint('Erreur vérification code promo: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  // ==================== USER SECURITY ====================

  /// Changer le mot de passe
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: await _getHeaders(),
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': 'Mot de passe changé avec succès'};
      }

      return {
        'success': false,
        'message':
            data['message'] ?? 'Erreur lors du changement de mot de passe',
      };
    } catch (e) {
      debugPrint('Erreur changement mot de passe: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }

  /// Supprimer le compte utilisateur
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/auth/delete-account'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': 'Compte supprimé avec succès'};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la suppression du compte',
      };
    } catch (e) {
      debugPrint('Erreur suppression compte: $e');
      return {'success': false, 'message': 'Erreur serveur'};
    }
  }
}
