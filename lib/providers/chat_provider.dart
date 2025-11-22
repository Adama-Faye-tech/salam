import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../services/api_chat_service.dart';
import '../services/supabase_service.dart';

class ChatProvider with ChangeNotifier {
  final List<Chat> _chats = [];
  final Map<String, List<ChatMessage>> _messages = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ChatMessage> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  int getUnreadCount(String chatId) {
    final messages = _messages[chatId] ?? [];
    return messages
        .where((m) => !m.isRead && m.receiverId == _currentUserId)
        .length;
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /// Charger toutes les conversations de l'utilisateur depuis l'API
  Future<void> loadUserConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiChatService.instance.getUserConversations();

      if (result['success']) {
        _chats.clear();
        final List<dynamic> chatsData = result['chats'];
        for (var chatData in chatsData) {
          _chats.add(Chat.fromJson(chatData));
        }
        _error = null;
      } else {
        _error = result['error'] ?? 'Erreur inconnue';
      }
    } catch (e) {
      _error = 'Erreur de connexion';
      debugPrint('❌ Erreur chargement conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer ou récupérer un chat existant avec un fournisseur
  Future<Chat?> createOrGetChat(
    String providerId,
    String providerName,
    String? providerAvatar, {
    String? equipmentId,
    String? equipmentName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Vérifier si un chat existe déjà
      final existingChat = _chats.firstWhere(
        (chat) =>
            chat.providerId == providerId && chat.equipmentId == equipmentId,
        orElse: () => Chat(
          id: '',
          userId: _currentUserId ?? '',
          providerId: '',
          providerName: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingChat.id.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return existingChat;
      }

      // Créer un nouveau chat via l'API
      final result = await ApiChatService.instance.createOrGetChat(
        providerId: providerId,
        equipmentId: equipmentId ?? '',
      );

      if (result['success']) {
        final newChat = Chat.fromJson(result['chat']);
        _chats.insert(0, newChat);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return newChat;
      } else {
        _error = result['error'] ?? 'Erreur création chat';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Erreur de connexion';
      debugPrint('❌ Erreur création/récupération chat: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Envoyer un message texte
  Future<bool> sendTextMessage(
    String chatId,
    String content,
    String receiverId,
  ) async {
    if (_currentUserId == null) return false;

    try {
      // Créer un message local temporaire
      final tempMessage = ChatMessage(
        id: Uuid().v4(),
        chatId: chatId,
        senderId: _currentUserId!,
        senderName: 'SAME',
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        type: MessageType.text,
        isRead: false,
        isSent: false,
      );

      // Ajouter immédiatement à la liste
      if (!_messages.containsKey(chatId)) {
        _messages[chatId] = [];
      }
      _messages[chatId]!.add(tempMessage);
      notifyListeners();

      // Envoyer à l'API
      final result = await ApiChatService.instance.sendMessage(
        chatId: chatId,
        content: content,
        type: 'text',
      );

      if (result['success']) {
        // Mettre à jour avec la réponse serveur
        final serverMessage = ChatMessage.fromJson(result['message']);
        final index = _messages[chatId]!.indexWhere(
          (m) => m.id == tempMessage.id,
        );
        if (index != -1) {
          _messages[chatId]![index] = serverMessage;
        }
        notifyListeners();
        return true;
      } else {
        // Supprimer le message temporaire en cas d'échec
        _messages[chatId]!.removeWhere((m) => m.id == tempMessage.id);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi message texte: $e');
      return false;
    }
  }

  /// Envoyer une image
  Future<bool> sendImageMessage(
    String chatId,
    String imagePath,
    String receiverId,
  ) async {
    if (_currentUserId == null) return false;

    try {
      // 1. Upload de l'image sur Supabase Storage
      debugPrint('📤 Upload image vers Supabase Storage bucket "chat"...');
      final fileName =
          'chat_${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';

      final imageUrl = await SupabaseService.instance.uploadFile(
        bucket: 'chat',
        path: fileName,
        file: File(imagePath),
      );

      debugPrint('✅ Image uploadée: $imageUrl');

      // 2. Créer le message temporaire avec l'URL
      final tempMessage = ChatMessage(
        id: Uuid().v4(),
        chatId: chatId,
        senderId: _currentUserId!,
        senderName: 'Moi',
        receiverId: receiverId,
        content: imageUrl, // URL Supabase au lieu du chemin local
        timestamp: DateTime.now(),
        type: MessageType.image,
        isRead: false,
        isSent: false,
      );

      if (!_messages.containsKey(chatId)) {
        _messages[chatId] = [];
      }
      _messages[chatId]!.add(tempMessage);
      notifyListeners();

      // 3. Envoyer le message avec l'URL à l'API
      final result = await ApiChatService.instance.sendMessage(
        chatId: chatId,
        content: imageUrl,
        type: 'image',
      );

      if (result['success']) {
        final serverMessage = ChatMessage.fromJson(result['message']);
        final index = _messages[chatId]!.indexWhere(
          (m) => m.id == tempMessage.id,
        );
        if (index != -1) {
          _messages[chatId]![index] = serverMessage;
        }
        notifyListeners();
        return true;
      } else {
        _messages[chatId]!.removeWhere((m) => m.id == tempMessage.id);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi image: $e');

      // Vérifier si c'est une erreur de bucket manquant
      if (e.toString().contains('not found') ||
          e.toString().contains('does not exist')) {
        debugPrint('⚠️ Le bucket "chat" n\'existe pas dans Supabase Storage');
        debugPrint(
          '📖 Consultez CONFIGURATION_SUPABASE_BUCKETS.md pour la configuration',
        );
      }

      return false;
    }
  }

  /// Envoyer un audio
  Future<bool> sendAudioMessage(
    String chatId,
    String audioPath,
    String receiverId,
    int duration,
  ) async {
    if (_currentUserId == null) return false;

    try {
      // 1. Upload de l'audio sur Supabase Storage
      debugPrint('📤 Upload audio vers Supabase Storage bucket "chat"...');
      final fileName =
          'chat_${DateTime.now().millisecondsSinceEpoch}_${audioPath.split('/').last}';

      final audioUrl = await SupabaseService.instance.uploadFile(
        bucket: 'chat',
        path: fileName,
        file: File(audioPath),
      );

      debugPrint('✅ Audio uploadé: $audioUrl');

      // 2. Créer le message temporaire avec l'URL
      final tempMessage = ChatMessage(
        id: Uuid().v4(),
        chatId: chatId,
        senderId: _currentUserId!,
        senderName: 'Moi',
        receiverId: receiverId,
        content: audioUrl, // URL Supabase au lieu du chemin local
        timestamp: DateTime.now(),
        type: MessageType.audio,
        audioDuration: duration,
        isRead: false,
        isSent: false,
      );

      if (!_messages.containsKey(chatId)) {
        _messages[chatId] = [];
      }
      _messages[chatId]!.add(tempMessage);
      notifyListeners();

      // 3. Envoyer le message avec l'URL à l'API
      final result = await ApiChatService.instance.sendMessage(
        chatId: chatId,
        content: audioUrl,
        type: 'audio',
      );

      if (result['success']) {
        final serverMessage = ChatMessage.fromJson(result['message']);
        final index = _messages[chatId]!.indexWhere(
          (m) => m.id == tempMessage.id,
        );
        if (index != -1) {
          _messages[chatId]![index] = serverMessage;
        }
        notifyListeners();
        return true;
      } else {
        _messages[chatId]!.removeWhere((m) => m.id == tempMessage.id);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi audio: $e');

      if (e.toString().contains('not found') ||
          e.toString().contains('does not exist')) {
        debugPrint('⚠️ Le bucket "chat" n\'existe pas dans Supabase Storage');
        debugPrint(
          '📖 Consultez CONFIGURATION_SUPABASE_BUCKETS.md pour la configuration',
        );
      }

      return false;
    }
  }

  /// Envoyer un document
  Future<bool> sendDocumentMessage(
    String chatId,
    String documentPath,
    String documentName,
    String receiverId,
    int fileSize,
  ) async {
    if (_currentUserId == null) return false;

    try {
      // 1. Upload du document sur Supabase Storage
      debugPrint('📤 Upload document vers Supabase Storage bucket "chat"...');
      final fileName =
          'chat_${DateTime.now().millisecondsSinceEpoch}_$documentName';

      final documentUrl = await SupabaseService.instance.uploadFile(
        bucket: 'chat',
        path: fileName,
        file: File(documentPath),
      );

      debugPrint('✅ Document uploadé: $documentUrl');

      // 2. Créer le message temporaire avec l'URL
      final tempMessage = ChatMessage(
        id: Uuid().v4(),
        chatId: chatId,
        senderId: _currentUserId!,
        senderName: 'Moi',
        receiverId: receiverId,
        content: documentUrl, // URL Supabase au lieu du chemin local
        timestamp: DateTime.now(),
        type: MessageType.document,
        fileName: documentName,
        fileSize: fileSize,
        isRead: false,
        isSent: false,
      );

      if (!_messages.containsKey(chatId)) {
        _messages[chatId] = [];
      }
      _messages[chatId]!.add(tempMessage);
      notifyListeners();

      // 3. Envoyer le message avec l'URL à l'API
      final result = await ApiChatService.instance.sendMessage(
        chatId: chatId,
        content: documentUrl,
        type: 'document',
      );

      if (result['success']) {
        final serverMessage = ChatMessage.fromJson(result['message']);
        final index = _messages[chatId]!.indexWhere(
          (m) => m.id == tempMessage.id,
        );
        if (index != -1) {
          _messages[chatId]![index] = serverMessage;
        }
        notifyListeners();
        return true;
      } else {
        _messages[chatId]!.removeWhere((m) => m.id == tempMessage.id);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi document: $e');

      if (e.toString().contains('not found') ||
          e.toString().contains('does not exist')) {
        debugPrint('⚠️ Le bucket "chat" n\'existe pas dans Supabase Storage');
        debugPrint(
          '📖 Consultez CONFIGURATION_SUPABASE_BUCKETS.md pour la configuration',
        );
      }

      return false;
    }
  }

  /// Marquer tous les messages d'un chat comme lus
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      // Mettre à jour localement avec copyWith
      if (_messages.containsKey(chatId)) {
        _messages[chatId] = _messages[chatId]!.map((message) {
          if (message.receiverId == _currentUserId && !message.isRead) {
            return message.copyWith(isRead: true);
          }
          return message;
        }).toList();
      }

      // Mettre à jour le chat
      final chatIndex = _chats.indexWhere((c) => c.id == chatId);
      if (chatIndex != -1) {
        final chat = _chats[chatIndex];
        _chats[chatIndex] = Chat(
          id: chat.id,
          userId: chat.userId,
          providerId: chat.providerId,
          providerName: chat.providerName,
          providerAvatar: chat.providerAvatar,
          equipmentId: chat.equipmentId,
          equipmentName: chat.equipmentName,
          lastMessage: chat.lastMessage,
          unreadCount: 0,
          createdAt: chat.createdAt,
          updatedAt: chat.updatedAt,
        );
      }

      notifyListeners();

      // Envoyer à l'API
      await ApiChatService.instance.markMessagesAsRead(chatId);
    } catch (e) {
      debugPrint('❌ Erreur marquage messages lus: $e');
    }
  }

  /// Charger les messages d'un chat depuis l'API
  Future<void> loadMessagesFromApi(String chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiChatService.instance.getChatMessages(chatId);

      if (result['success']) {
        final List<dynamic> messagesData = result['messages'];
        _messages[chatId] = messagesData
            .map((data) => ChatMessage.fromJson(data))
            .toList();

        // Trier par date
        _messages[chatId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        _error = null;
      } else {
        _error = result['error'] ?? 'Erreur chargement messages';
      }
    } catch (e) {
      _error = 'Erreur de connexion';
      debugPrint('❌ Erreur chargement messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nettoyer les ressources
  @override
  void dispose() {
    super.dispose();
  }
}
