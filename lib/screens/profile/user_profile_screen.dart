import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../chat/chat_screen.dart';
import '../auth/login_screen.dart';

/// Écran pour afficher le profil public d'un utilisateur (prestataire ou agriculteur)
class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userPhone;
  final String? userLocation;
  final String? userPhotoUrl;
  final String? userDescription;
  final UserType? userType;
  final double? rating;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userLocation,
    this.userPhotoUrl,
    this.userDescription,
    this.userType,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              
              if (!userProvider.isAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                return;
              }
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    providerId: userId,
                    providerName: userName,
                    providerAvatar: userPhotoUrl,
                  ),
                ),
              );
            },
            tooltip: 'Envoyer un message',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Photo de profil
            CircleAvatar(
              radius: 60,
              backgroundImage: userPhotoUrl != null
                  ? NetworkImage(userPhotoUrl!)
                  : null,
              child: userPhotoUrl == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            const SizedBox(height: 16),
            // Nom
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Type d'utilisateur
            if (userType != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: userType == UserType.provider
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  userType == UserType.provider ? 'Prestataire' : 'Agriculteur',
                  style: TextStyle(
                    color: userType == UserType.provider
                        ? Colors.blue[700]
                        : Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Note
            if (rating != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // Informations de contact
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (userPhone != null)
                    _buildInfoRow(
                      context,
                      Icons.phone,
                      'Téléphone',
                      userPhone!,
                      onTap: () async {
                        final phoneNumber = userPhone!.replaceAll(RegExp(r'\s+'), '');
                        final uri = Uri.parse('tel:$phoneNumber');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Impossible d\'ouvrir l\'application téléphone'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  if (userLocation != null)
                    _buildInfoRow(
                      context,
                      Icons.location_on,
                      'Localisation',
                      userLocation!,
                    ),
                  if (userDescription != null) ...[
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'À propos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userDescription!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Bouton de contact
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    
                    if (!userProvider.isAuthenticated) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                      return;
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          providerId: userId,
                          providerName: userName,
                          providerAvatar: userPhotoUrl,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Envoyer un message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}