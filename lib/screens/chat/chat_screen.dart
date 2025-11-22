import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/chat_model.dart';
import '../../config/theme.dart';
import '../profile/user_profile_screen.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String? providerAvatar;
  final String? equipmentId;
  final String? equipmentName;

  const ChatScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    this.providerAvatar,
    this.equipmentId,
    this.equipmentName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRecording = false;
  Chat? _currentChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    try {
      final userProvider = context.read<UserProvider>();
      final chatProvider = context.read<ChatProvider>();

      if (!userProvider.isAuthenticated) {
        return;
      }

      // Créer ou récupérer le chat via le provider (qui gère l'API)
      final chat = await chatProvider.createOrGetChat(
        widget.providerId,
        widget.providerName,
        widget.providerAvatar,
        equipmentId: widget.equipmentId,
        equipmentName: widget.equipmentName,
      );

      setState(() {
        _currentChat = chat;
      });

      // Charger les messages du chat depuis l'API
      if (chat != null) {
        await chatProvider.loadMessagesFromApi(chat.id);
      }
    } catch (e) {
      debugPrint('Erreur initialisation chat: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentChat == null) return;

    try {
      final chatProvider = context.read<ChatProvider>();

      await chatProvider.sendTextMessage(
        _currentChat!.id,
        text,
        widget.providerId,
      );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'envoi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && _currentChat != null) {
        await chatProvider.sendImageMessage(
          _currentChat!.id,
          image.path,
          widget.providerId,
        );

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('📷 Image envoyée'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && _currentChat != null) {
        final file = result.files.single;

        await chatProvider.sendDocumentMessage(
          _currentChat!.id,
          file.path!,
          file.name,
          widget.providerId,
          file.size,
        );

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('📄 Document envoyé'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      // Arrêter l'enregistrement
      setState(() {
        _isRecording = false;
      });

      // Enregistrement audio : implémentation basique
      // Note: Pour une implémentation complète, utiliser record package
      // et implémenter la permission microphone + gestion fichiers audio
      if (_currentChat != null) {
        try {
          final chatProvider = context.read<ChatProvider>();

          // Simuler l'envoi d'un message audio
          // Dans une vraie implémentation, remplacer par le chemin du fichier audio enregistré
          await chatProvider.sendAudioMessage(
            _currentChat!.id,
            '/tmp/audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
            widget.providerId,
            5, // Durée simulée en secondes
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎤 Audio envoyé'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else {
      // Démarrer l'enregistrement
      setState(() {
        _isRecording = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Enregistrement en cours...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Enregistrement audio : implémentation basique
      // Note: Pour une implémentation complète avec vraie fonctionnalité audio:
      // 1. Ajouter le package 'record' au pubspec.yaml
      // 2. Demander la permission microphone (permission_handler)
      // 3. Créer un fichier temporaire pour l'audio
      // 4. Utiliser Record().start() pour commencer l'enregistrement
      // 5. Sauvegarder le fichier et l'uploader vers le serveur
      // 6. Envoyer le chemin du fichier audio dans le message
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final userProvider = context.watch<UserProvider>();
    final messages = _currentChat != null
        ? chatProvider.getMessages(_currentChat!.id)
        : <ChatMessage>[];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.providerAvatar != null &&
                widget.providerAvatar!.isNotEmpty)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.providerAvatar!),
              )
            else
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 16),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.providerName,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Bouton pour voir le profil du prestataire
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Voir le profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: widget.providerId,
                    userName: widget.providerName,
                    userPhotoUrl: widget.providerAvatar,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.equipmentName != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conversation au sujet de: ${widget.equipmentName}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: chatProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez la conversation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMe =
                          userProvider.currentUser != null &&
                          message.senderId == userProvider.currentUser!.id;
                      return _buildMessage(message, isMe);
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickDocument,
                      color: AppColors.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: _pickImage,
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Écrire un message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: _isRecording ? Colors.red : AppColors.primary,
                      ),
                      onPressed: _toggleAudioRecording,
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, bool isMe) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(message, isMe);
      case MessageType.image:
        return _buildImageMessage(message, isMe);
      case MessageType.document:
        return _buildDocumentMessage(message, isMe);
      case MessageType.audio:
        return _buildAudioMessage(message, isMe);
    }
  }

  Widget _buildTextMessage(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(message.content),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentMessage(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.insert_drive_file, size: 40),
            const SizedBox(height: 8),
            Text(
              message.fileName ?? 'Document',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message.fileSize != null)
              Text(
                '${(message.fileSize! / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMessage(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_filled,
                  size: 40,
                  color: isMe ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message vocal',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (message.audioDuration != null)
                        Text(
                          '${message.audioDuration} secondes',
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
