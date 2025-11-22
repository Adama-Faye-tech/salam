import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';

class NotificationsProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get todayNotifications {
    return _notifications
        .where((n) => n.getTimeCategory() == "Aujourd'hui")
        .toList();
  }

  List<NotificationModel> get yesterdayNotifications {
    return _notifications.where((n) => n.getTimeCategory() == "Hier").toList();
  }

  List<NotificationModel> get thisWeekNotifications {
    return _notifications
        .where((n) => n.getTimeCategory() == "Cette semaine")
        .toList();
  }

  List<NotificationModel> get olderNotifications {
    return _notifications
        .where((n) => n.getTimeCategory() == "Plus anciennes")
        .toList();
  }

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        _error = 'Utilisateur non connecté';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Charger les notifications depuis Supabase
      final response = await _supabase.notifications
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _notifications = response
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      try {
        // Mettre à jour dans Supabase
        await _supabase.notifications
            .update({'is_read': true})
            .eq('id', notificationId);
      } catch (e) {
        debugPrint('Erreur markAsRead: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();

    try {
      final user = _supabase.currentUser;
      if (user != null) {
        // Marquer toutes les notifications de l'utilisateur comme lues
        await _supabase.notifications
            .update({'is_read': true})
            .eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('Erreur markAllAsRead: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    try {
      // Supprimer la notification dans Supabase
      await _supabase.notifications.delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('Erreur deleteNotification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    notifyListeners();

    try {
      final user = _supabase.currentUser;
      if (user != null) {
        // Supprimer toutes les notifications de l'utilisateur
        await _supabase.notifications.delete().eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('Erreur clearAllNotifications: $e');
    }
  }
}
