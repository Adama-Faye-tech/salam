import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_auth_service.dart';
import 'package:flutter/foundation.dart';

/// Service API pour la gestion des discussions (chats)
class ApiChatService {
  static final ApiChatService instance = ApiChatService._();
  ApiChatService._();

  /// Obtenir toutes les conversations de l'utilisateur
  Future<Map<String, dynamic>> getUserConversations() async {
    try {
      final token = await ApiAuthService.instance.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Non authentifié',
        };
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/chat/conversations');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'conversations': data['data'] as List,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la récupération des conversations',
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération conversations: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// CràƒÆ’à‚©er ou ràƒÆ’à‚©cupàƒÆ’à‚©rer une conversation
  Future<Map<String, dynamic>> createOrGetChat({
    required String providerId,
    required String equipmentId,
  }) async {
    try {
      final token = await ApiAuthService.instance.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Non authentifié',
        };
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/chat/create');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'providerId': providerId,
          'equipmentId': equipmentId,
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return {
          'success': true,
          'chat': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la création de la conversation',
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur création chat: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// Obtenir les messages d'une conversation
  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    try {
      final token = await ApiAuthService.instance.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Non authentifié',
        };
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/chat/$chatId/messages');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'messages': data['data'] as List,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la récupération des messages',
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération messages: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// Envoyer un message texte
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String type,
    String? content,
    String? fileUrl,
  }) async {
    try {
      final token = await ApiAuthService.instance.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Non authentifié',
        };
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/chat/$chatId/send');
      final body = <String, dynamic>{
        'type': type,
      };

      if (content != null) body['content'] = content;
      if (fileUrl != null) body['fileUrl'] = fileUrl;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'envoi du message',
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi message: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// Marquer les messages comme lus
  Future<Map<String, dynamic>> markMessagesAsRead(String chatId) async {
    try {
      final token = await ApiAuthService.instance.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Non authentifié',
        };
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/chat/$chatId/mark-read');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du marquage des messages',
        };
      }
    } catch (e) {
      debugPrint('â❌ Erreur marquage messages lus: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }
}



