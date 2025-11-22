enum MessageType {
  text,
  image,
  audio,
  document,
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final MessageType type;
  final String content; // Texte ou URL du fichier
  final String? fileName; // Pour les documents
  final int? fileSize; // En bytes
  final int? audioDuration; // En secondes pour l'audio
  final DateTime timestamp;
  final bool isRead;
  final bool isSent;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.type,
    required this.content,
    this.fileName,
    this.fileSize,
    this.audioDuration,
    required this.timestamp,
    this.isRead = false,
    this.isSent = true,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      receiverId: json['receiver_id'],
      type: MessageType.values[json['type']],
      content: json['content'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      audioDuration: json['audio_duration'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      isSent: json['is_sent'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'receiver_id': receiverId,
      'type': type.index,
      'content': content,
      'file_name': fileName,
      'file_size': fileSize,
      'audio_duration': audioDuration,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'is_sent': isSent,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? receiverId,
    MessageType? type,
    String? content,
    String? fileName,
    int? fileSize,
    int? audioDuration,
    DateTime? timestamp,
    bool? isRead,
    bool? isSent,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      audioDuration: audioDuration ?? this.audioDuration,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
    );
  }
}

class Chat {
  final String id;
  final String userId;
  final String providerId;
  final String providerName;
  final String? providerAvatar;
  final String? equipmentId;
  final String? equipmentName;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.providerName,
    this.providerAvatar,
    this.equipmentId,
    this.equipmentName,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      userId: json['user_id'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      providerAvatar: json['provider_avatar'],
      equipmentId: json['equipment_id'],
      equipmentName: json['equipment_name'],
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider_id': providerId,
      'provider_name': providerName,
      'provider_avatar': providerAvatar,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

