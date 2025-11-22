import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import 'database_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _uuid = const Uuid();

  // CràƒÆ’à‚©er une notification dans la base de donnàƒÆ’à‚©es
  Future<void> _createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? orderId,
  }) async {
    try {
      final db = DatabaseService.instance;
      final notifId = 'notif_${_uuid.v4()}';

      await db.execute(
        '''
        INSERT INTO notifications (
          id, user_id, type, title, message, order_id, is_read, created_at
        ) VALUES (
          @id, @userId, @type, @title, @message, @orderId, false, NOW()
        )
        ''',
        {
          'id': notifId,
          'userId': userId,
          'type': _notificationTypeToString(type),
          'title': title,
          'message': message,
          'orderId': orderId,
        },
      );

      debugPrint('â✓¬Å“ Notification cràƒÆ’à‚©àƒÆ’à‚©e: $title pour user $userId');
    } catch (e) {
      debugPrint('Erreur cràƒÆ’à‚©ation notification: $e');
    }
  }

  // Notification lors de la cràƒÆ’à‚©ation d'une commande
  Future<void> notifyOrderCreated({
    required String userId,
    required String providerId,
    required Order order,
  }) async {
    // Notification pour l'utilisateur
    await _createNotification(
      userId: userId,
      type: NotificationType.orderStatus,
      title: 'RàƒÆ’à‚©servation envoyàƒÆ’à‚©e',
      message: 'Votre ràƒÆ’à‚©servation de ${order.itemName} a àƒÆ’à‚©tàƒÆ’à‚© envoyàƒÆ’à‚©e au prestataire. En attente de confirmation.',
      orderId: order.id,
    );

    // Notification pour le prestataire
    await _createNotification(
      userId: providerId,
      type: NotificationType.orderStatus,
      title: 'Nouvelle ràƒÆ’à‚©servation',
      message: 'Vous avez reàƒÆ’à‚§u une nouvelle demande de ràƒÆ’à‚©servation pour ${order.itemName}.',
      orderId: order.id,
    );
  }

  // Notification lors de la confirmation d'une commande
  Future<void> notifyOrderConfirmed({
    required String userId,
    required String providerId,
    required Order order,
  }) async {
    // Notification pour l'utilisateur
    await _createNotification(
      userId: userId,
      type: NotificationType.orderStatus,
      title: 'RàƒÆ’à‚©servation confirmàƒÆ’à‚©e â✓¬Å“',
      message: 'Votre ràƒÆ’à‚©servation de ${order.itemName} a àƒÆ’à‚©tàƒÆ’à‚© confirmàƒÆ’à‚©e ! Rendez-vous le ${_formatDate(order.startDate)}.',
      orderId: order.id,
    );
  }

  // Notification lors du dàƒÆ’à‚©but d'une commande
  Future<void> notifyOrderInProgress({
    required String userId,
    required String providerId,
    required Order order,
  }) async {
    // Notification pour l'utilisateur
    await _createNotification(
      userId: userId,
      type: NotificationType.orderStatus,
      title: 'Service en cours',
      message: 'Votre ràƒÆ’à‚©servation de ${order.itemName} est maintenant en cours.',
      orderId: order.id,
    );
  }

  // Notification lors de la fin d'une commande
  Future<void> notifyOrderCompleted({
    required String userId,
    required String providerId,
    required Order order,
  }) async {
    // Notification pour l'utilisateur
    await _createNotification(
      userId: userId,
      type: NotificationType.orderStatus,
      title: 'Service terminàƒÆ’à‚©',
      message: 'Votre ràƒÆ’à‚©servation de ${order.itemName} est terminàƒÆ’à‚©e. N\'oubliez pas de laisser un avis !',
      orderId: order.id,
    );

    // Notification pour le prestataire
    await _createNotification(
      userId: providerId,
      type: NotificationType.orderStatus,
      title: 'Service terminàƒÆ’à‚©',
      message: 'Le service ${order.itemName} est marquàƒÆ’à‚© comme terminàƒÆ’à‚©.',
      orderId: order.id,
    );
  }

  // Notification lors de l'annulation d'une commande
  Future<void> notifyOrderCancelled({
    required String userId,
    required String providerId,
    required Order order,
    required String cancelReason,
  }) async {
    // Notification pour l'utilisateur
    await _createNotification(
      userId: userId,
      type: NotificationType.orderStatus,
      title: 'RàƒÆ’à‚©servation annulàƒÆ’à‚©e',
      message: 'Votre ràƒÆ’à‚©servation de ${order.itemName} a àƒÆ’à‚©tàƒÆ’à‚© annulàƒÆ’à‚©e. Raison: $cancelReason',
      orderId: order.id,
    );

    // Notification pour le prestataire
    await _createNotification(
      userId: providerId,
      type: NotificationType.orderStatus,
      title: 'RàƒÆ’à‚©servation annulàƒÆ’à‚©e',
      message: 'La ràƒÆ’à‚©servation de ${order.itemName} a àƒÆ’à‚©tàƒÆ’à‚© annulàƒÆ’à‚©e.',
      orderId: order.id,
    );
  }

  // Notification de rappel avant une ràƒÆ’à‚©servation (24h avant)
  Future<void> notifyOrderReminder({
    required String userId,
    required Order order,
  }) async {
    await _createNotification(
      userId: userId,
      type: NotificationType.orderStatus,
      title: 'Rappel de ràƒÆ’à‚©servation',
      message: 'Votre ràƒÆ’à‚©servation de ${order.itemName} commence demain àƒÆ’à‚  ${order.location}.',
      orderId: order.id,
    );
  }

  // Notification de nouveau message
  Future<void> notifyNewMessage({
    required String userId,
    required String senderName,
    required String messagePreview,
  }) async {
    await _createNotification(
      userId: userId,
      type: NotificationType.message,
      title: 'Nouveau message',
      message: '$senderName: $messagePreview',
    );
  }

  // Notification de promotion
  Future<void> notifyPromotion({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _createNotification(
      userId: userId,
      type: NotificationType.offer,
      title: title,
      message: message,
    );
  }

  // Notification systàƒÆ’à‚¨me
  Future<void> notifySystem({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _createNotification(
      userId: userId,
      type: NotificationType.system,
      title: title,
      message: message,
    );
  }

  // RàƒÆ’à‚©cupàƒÆ’à‚©rer toutes les notifications d'un utilisateur
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final db = DatabaseService.instance;
      final results = await db.query(
        '''
        SELECT * FROM notifications 
        WHERE user_id = @userId 
        ORDER BY created_at DESC
        ''',
        {'userId': userId},
      );

      return results.map((map) => _notificationFromMap(map)).toList();
    } catch (e) {
      debugPrint('Erreur ràƒÆ’à‚©cupàƒÆ’à‚©ration notifications: $e');
      return [];
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      final db = DatabaseService.instance;
      await db.execute(
        'UPDATE notifications SET is_read = true WHERE id = @id',
        {'id': notificationId},
      );
    } catch (e) {
      debugPrint('Erreur marquage notification: $e');
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead(String userId) async {
    try {
      final db = DatabaseService.instance;
      await db.execute(
        'UPDATE notifications SET is_read = true WHERE user_id = @userId',
        {'userId': userId},
      );
    } catch (e) {
      debugPrint('Erreur marquage toutes notifications: $e');
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final db = DatabaseService.instance;
      await db.execute(
        'DELETE FROM notifications WHERE id = @id',
        {'id': notificationId},
      );
    } catch (e) {
      debugPrint('Erreur suppression notification: $e');
    }
  }

  // Supprimer toutes les notifications lues
  Future<int> deleteReadNotifications(String userId) async {
    try {
      final db = DatabaseService.instance;
      return await db.execute(
        'DELETE FROM notifications WHERE user_id = @userId AND is_read = true',
        {'userId': userId},
      );
    } catch (e) {
      debugPrint('Erreur suppression notifications lues: $e');
      return 0;
    }
  }

  // Helpers
  String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.orderStatus:
        return 'order_update';
      case NotificationType.payment:
        return 'payment';
      case NotificationType.message:
        return 'message';
      case NotificationType.system:
        return 'system';
      case NotificationType.offer:
        return 'promotion';
      case NotificationType.sale:
      case NotificationType.update:
      case NotificationType.security:
      case NotificationType.recommendation:
      case NotificationType.reminder:
      case NotificationType.news:
      case NotificationType.general:
        return type.toString().split('.').last;
    }
  }

  NotificationType _stringToNotificationType(String type) {
    switch (type) {
      case 'order_update':
        return NotificationType.orderStatus;
      case 'payment':
        return NotificationType.payment;
      case 'message':
        return NotificationType.message;
      case 'system':
        return NotificationType.system;
      case 'promotion':
        return NotificationType.offer;
      default:
        return NotificationType.system;
    }
  }

  NotificationModel _notificationFromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: _stringToNotificationType(map['type'] as String),
      title: map['title'] as String,
      message: map['message'] as String,
      orderId: map['order_id'] as String?,
      isRead: map['is_read'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'fàƒÆ’à‚©vrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aoàƒÆ’à‚»t', 'septembre', 'octobre', 'novembre', 'dàƒÆ’à‚©cembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}



