class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.orderId,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.general,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      orderId: json['orderId'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.general,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      orderId: map['order_id'],
      isRead: map['is_read'] == 1 || map['is_read'] == true,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? orderId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  /// Retourne la catégorie temporelle de la notification
  String getTimeCategory() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inHours < 24 && createdAt.day == now.day) {
      return "Aujourd'hui";
    } else if (difference.inHours < 48 &&
        createdAt.day == now.subtract(const Duration(days: 1)).day) {
      return "Hier";
    } else if (difference.inDays < 7) {
      return "Cette semaine";
    } else {
      return "Plus anciennes";
    }
  }
}

enum NotificationType {
  orderStatus, // Statut de commande
  payment, // Paiement
  message, // Nouveau message
  system, // Notification système
  sale, // Alerte de vente
  update, // Mise à jour de liste
  security, // Alerte de sécurité
  offer, // Offre exclusive
  recommendation, // Recommandation
  reminder, // Rappel
  news, // Actualités
  general, // Général
}
