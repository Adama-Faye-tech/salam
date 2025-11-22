import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/notification_model.dart';
import '../auth/login_screen.dart';
import '../orders/orders_screen.dart';
import '../chat/chat_list_screen.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Les notifications sont déjàƒ  chargées depuis le HomeScreen
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    // Si non connecté, afficher message de connexion
    if (!userProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Connectez-vous pour voir vos notifications',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  provider.markAllAsRead();
                },
                child: const Text('Tout marquer comme lu'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune notification'),
                ],
              ),
            );
          }

          return ListView(
            children: [
              if (provider.todayNotifications.isNotEmpty) ...[
                _buildSectionHeader('Aujourd\'hui'),
                ...provider.todayNotifications.map(
                  (n) => _buildNotificationItem(n),
                ),
              ],
              if (provider.yesterdayNotifications.isNotEmpty) ...[
                _buildSectionHeader('Hier'),
                ...provider.yesterdayNotifications.map(
                  (n) => _buildNotificationItem(n),
                ),
              ],
              if (provider.thisWeekNotifications.isNotEmpty) ...[
                _buildSectionHeader('Cette semaine'),
                ...provider.thisWeekNotifications.map(
                  (n) => _buildNotificationItem(n),
                ),
              ],
              if (provider.olderNotifications.isNotEmpty) ...[
                _buildSectionHeader('Plus anciennes'),
                ...provider.olderNotifications.map(
                  (n) => _buildNotificationItem(n),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    switch (notification.type) {
      case NotificationType.orderStatus:
      case NotificationType.payment:
        // Navigation vers l'écran des commandes
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrdersScreen()),
        );
        break;
      case NotificationType.message:
        // Navigation vers l'écran des conversations
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
        break;
      case NotificationType.sale:
      case NotificationType.offer:
      case NotificationType.recommendation:
        // Si une notification contient un ID d'équipement dans data
        if (notification.data != null &&
            notification.data!['equipmentId'] != null) {
          // Navigation vers les détails de l'équipement
          // Note: Nécessite de charger l'équipement depuis le provider
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voir les détails de l\'équipement')),
          );
        }
        break;
      case NotificationType.system:
      case NotificationType.security:
      case NotificationType.update:
      case NotificationType.reminder:
      case NotificationType.news:
      case NotificationType.general:
        // Pas de navigation spécifique
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(notification.message)));
        break;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[100],
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.orderStatus:
        icon = Icons.shopping_bag;
        iconColor = Colors.blue;
        break;
      case NotificationType.sale:
        icon = Icons.local_offer;
        iconColor = Colors.red;
        break;
      case NotificationType.update:
        icon = Icons.update;
        iconColor = Colors.orange;
        break;
      case NotificationType.security:
        icon = Icons.security;
        iconColor = Colors.red;
        break;
      case NotificationType.offer:
        icon = Icons.card_giftcard;
        iconColor = Colors.purple;
        break;
      case NotificationType.recommendation:
        icon = Icons.recommend;
        iconColor = Colors.green;
        break;
      case NotificationType.reminder:
        icon = Icons.alarm;
        iconColor = Colors.orange;
        break;
      case NotificationType.news:
        icon = Icons.newspaper;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        context.read<NotificationsProvider>().deleteNotification(
          notification.id,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification supprimée')));
      },
      child: Container(
        color: notification.isRead ? null : Colors.blue.withValues(alpha: 0.05),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.2),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationsProvider>().markAsRead(notification.id);
            }
            _handleNotificationTap(context, notification);
          },
        ),
      ),
    );
  }
}
