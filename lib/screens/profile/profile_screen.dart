import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/user_provider.dart';
import 'edit_profile_screen.dart';
import '../equipment/new_equipment_screen.dart';
import '../equipment/my_equipment_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../chat/chat_list_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.isAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Partager mon profil',
                  onPressed: () =>
                      _shareProfile(context, userProvider.currentUser!.id),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;

          if (!userProvider.isAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 120,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Non connecté',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connectez-vous pour accéder à votre profil',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Créer un compte'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // En-tête profil sans gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Photo de profil
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            child: user?.photoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      user!.photoUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            );
                                          },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context).primaryColor,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Nom
                      Text(
                        user?.name ?? 'Utilisateur',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Email
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Adresse
                      if (user?.address != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user!.address!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.edit,
                        title: 'Modifier mon profil',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildSectionTitle('Mes équipements'),
                      _buildMenuItem(
                        context,
                        icon: Icons.inventory,
                        title: 'Mes équipements',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyEquipmentScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.add_business,
                        title: 'Publier un équipement',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NewEquipmentScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.message,
                        title: 'Mes messages',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatListScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildSectionTitle('Aide & Support'),
                      _buildMenuItem(
                        context,
                        icon: Icons.help,
                        title: 'Centre d\'aide',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Centre d\'aide à venir'),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.info,
                        title: 'À propos',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'SALAM',
                            applicationVersion: '1.0.0',
                            applicationIcon: const Icon(
                              Icons.agriculture,
                              size: 48,
                            ),
                            children: [
                              const Text(
                                'Application de location de matériel agricole',
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.logout,
                        title: 'Se déconnecter',
                        textColor: Colors.red,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Déconnexion'),
                              content: const Text(
                                'Voulez-vous vraiment vous déconnecter ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Déconnexion'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            await userProvider.logout();
                            if (context.mounted) {
                              // Rediriger vers l'écran de connexion et effacer tout l'historique
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Déconnexion réussie'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Theme.of(context).primaryColor),
      title: Text(title, style: TextStyle(fontSize: 16, color: textColor)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  /// Partage le profil utilisateur via un lien web avec Open Graph
  void _shareProfile(BuildContext context, String userId) async {
    try {
      // URL de l'API (à configurer selon votre environnement)
      const apiUrl =
          'http://localhost:3000'; // TODO: Remplacer par votre URL de production
      final profileUrl = '$apiUrl/api/profile/share/$userId';

      // Afficher un dialogue avec options
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.share, size: 48, color: Color(0xFF4CAF50)),
              const SizedBox(height: 16),
              const Text(
                'Partager mon profil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Partagez votre profil professionnel avec vos contacts',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Bouton Partager
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Share.share(
                      'Découvrez mon profil sur SAME - Location de matériel agricole\n\n$profileUrl',
                      subject: 'Mon profil SAME',
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Partager le lien'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bouton Copier le lien
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: profileUrl));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Lien copié dans le presse-papier'),
                          backgroundColor: Color(0xFF4CAF50),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier le lien'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Afficher le lien
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        profileUrl,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
