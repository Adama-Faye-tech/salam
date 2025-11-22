import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import 'chat_screen.dart';
import '../auth/login_screen.dart';
import 'package:intl/intl.dart';

/// Écran listant toutes les conversations de l'utilisateur
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.isAuthenticated) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.loadUserConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes discussions'),
      ),
      body: Consumer2<UserProvider, ChatProvider>(
        builder: (context, userProvider, chatProvider, _) {
          // Si l'utilisateur n'est pas connecté
          if (!userProvider.isAuthenticated) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connectez-vous pour voir vos discussions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
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

          // Si les discussions sont en cours de chargement
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si une erreur s'est produite
          if (chatProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      chatProvider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadConversations,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Si aucune discussion
          if (chatProvider.chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune discussion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commencez par contacter un prestataire depuis la page d\'un équipement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Liste des discussions
          return RefreshIndicator(
            onRefresh: _loadConversations,
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: chatProvider.chats.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];
                return _buildChatTile(chat);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatTile(dynamic chat) {
    final userProvider = context.read<UserProvider>();
    final currentUserId = userProvider.currentUser?.id ?? '';
    
    // Déterminer le nom de l'autre personne
    final isProvider = currentUserId == chat.providerId;
    final otherPersonName = isProvider ? chat.clientName : chat.providerName;
    final equipmentName = chat.equipmentName ?? 'Équipement';
    
    // Dernier message
    final lastMessage = chat.lastMessage;
    final lastMessageTime = chat.lastMessageTime != null 
        ? _formatDateTime(DateTime.parse(chat.lastMessageTime))
        : '';
    
    // Nombre de messages non lus
    final unreadCount = chat.unreadCount ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Icon(
          Icons.person,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherPersonName ?? 'Utilisateur',
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastMessageTime.isNotEmpty)
            Text(
              lastMessageTime,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            equipmentName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastMessage ?? 'Aucun message',
                  style: TextStyle(
                    fontSize: 14,
                    color: unreadCount > 0 ? Colors.black87 : Colors.grey[700],
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              providerId: chat.providerId,
              providerName: chat.providerName,
              equipmentId: chat.equipmentId,
              equipmentName: equipmentName,
            ),
          ),
        ).then((_) => _loadConversations());
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'fr_FR').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }
}


