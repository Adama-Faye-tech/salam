import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  String _language = 'Français';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Section Compte
          _buildSectionHeader('Compte'),
          if (user != null) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? Text(user.name[0].toUpperCase())
                    : null,
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Se connecter'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],

          const Divider(),

          // Section Notifications
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Activer les notifications'),
            subtitle: const Text('Recevoir toutes les notifications'),
            value: _notificationsEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                if (!value) {
                  _emailNotifications = false;
                  _pushNotifications = false;
                }
              });
              _showSuccessSnackBar(
                'Notifications ${value ? "activées" : "désactivées"}',
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined),
            title: const Text('Notifications par email'),
            subtitle: const Text('Recevoir des emails'),
            value: _emailNotifications,
            activeTrackColor: AppColors.primary,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() => _emailNotifications = value);
                    _showSuccessSnackBar(
                      'Emails ${value ? "activés" : "désactivés"}',
                    );
                  }
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.phone_android_outlined),
            title: const Text('Notifications push'),
            subtitle: const Text('Notifications sur l\'appareil'),
            value: _pushNotifications,
            activeTrackColor: AppColors.primary,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() => _pushNotifications = value);
                    _showSuccessSnackBar(
                      'Push ${value ? "activées" : "désactivées"}',
                    );
                  }
                : null,
          ),

          const Divider(),

          // Section Apparence
          _buildSectionHeader('Apparence'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Thème de l\'application'),
                    subtitle: Text(_getThemeModeName(themeProvider.themeMode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(themeProvider),
                  ),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Langue'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(),
          ),

          const Divider(),

          // Section Confidentialité
          _buildSectionHeader('Confidentialité et sécurité'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyPolicy(),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Conditions d\'utilisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTermsOfService(),
          ),

          const Divider(),

          // Section Application
          _buildSectionHeader('Application'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            subtitle: Text('Version $_appVersion'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode_outlined),
            title: const Text('Informations techniques'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTechnicalInfo(),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Aide et support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHelp(),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Évaluer l\'application'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showSuccessSnackBar('Merci pour votre soutien !');
            },
          ),

          const Divider(),

          // Section Compte (Déconnexion/Suppression)
          if (user != null) ...[
            _buildSectionHeader('Gestion du compte'),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: () => _confirmLogout(),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Supprimer mon compte',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _confirmDeleteAccount(),
            ),
          ],

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  'SALAM - Société Agricole Locale pour l\'Amélioration et la Modernisation',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2025 - Version $_appVersion',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('✓ $message')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('✗ $message')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thème de l\'application'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Clair'),
                subtitle: const Text('Toujours en mode clair'),
                value: ThemeMode.light,
                // ignore: deprecated_member_use
                groupValue: themeProvider.themeMode,
                activeColor: AppColors.primary,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                    _showSuccessSnackBar('Mode clair activé');
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Sombre'),
                subtitle: const Text('Toujours en mode sombre'),
                value: ThemeMode.dark,
                // ignore: deprecated_member_use
                groupValue: themeProvider.themeMode,
                activeColor: AppColors.primary,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                    _showSuccessSnackBar('Mode sombre activé');
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Système'),
                subtitle: const Text('Suit les paramètres du système'),
                value: ThemeMode.system,
                // ignore: deprecated_member_use
                groupValue: themeProvider.themeMode,
                activeColor: AppColors.primary,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                    _showSuccessSnackBar('Mode système activé');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              label: 'Français',
              value: 'Français',
              onSelected: () {
                setState(() => _language = 'Français');
                Navigator.pop(context);
                _showSuccessSnackBar('Langue changée : Français');
              },
            ),
            _buildLanguageOption(
              label: 'English',
              value: 'English',
              onSelected: () {
                setState(() => _language = 'English');
                Navigator.pop(context);
                _showSuccessSnackBar('Language changed: English');
              },
            ),
            _buildLanguageOption(
              label: 'العربية',
              value: 'العربية',
              onSelected: () {
                setState(() => _language = 'العربية');
                Navigator.pop(context);
                _showSuccessSnackBar('تم تغيير اللغة');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String value,
    required VoidCallback onSelected,
  }) {
    final isSelected = _language == value;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.primary : Colors.grey,
      ),
      title: Text(label),
      onTap: onSelected,
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              // Validation
              if (oldPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                Navigator.pop(context);
                _showErrorSnackBar('Tous les champs sont requis');
                return;
              }

              if (newPassword.length < 6) {
                Navigator.pop(context);
                _showErrorSnackBar(
                  'Le nouveau mot de passe doit contenir au moins 6 caractères',
                );
                return;
              }

              if (newPassword != confirmPassword) {
                Navigator.pop(context);
                _showErrorSnackBar('Les mots de passe ne correspondent pas');
                return;
              }

              Navigator.pop(context);

              // Appel API
              final apiService = ApiService();
              final result = await apiService.changePassword(
                oldPassword: oldPassword,
                newPassword: newPassword,
              );

              if (result['success'] == true) {
                _showSuccessSnackBar(
                  result['message'] ?? 'Mot de passe changé avec succès',
                );
              } else {
                _showErrorSnackBar(
                  result['message'] ??
                      'Erreur lors du changement de mot de passe',
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'SALAM respecte votre vie privée.\n\n'
            '1. Collecte de données\n'
            'Nous collectons uniquement les données nécessaires au fonctionnement de l\'application.\n\n'
            '2. Utilisation des données\n'
            'Vos données sont utilisées pour améliorer votre expérience.\n\n'
            '3. Partage des données\n'
            'Nous ne partageons pas vos données avec des tiers.\n\n'
            '4. Sécurité\n'
            'Vos données sont sécurisées et cryptées.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conditions d\'utilisation'),
        content: const SingleChildScrollView(
          child: Text(
            'CONDITIONS D\'UTILISATION DE SALAM\n\n'
            '1. Acceptation des conditions\n'
            'En utilisant cette application, vous acceptez ces conditions.\n\n'
            '2. Utilisation du service\n'
            'Vous vous engagez à utiliser le service de manière responsable.\n\n'
            '3. Responsabilités\n'
            'Vous êtes responsable du matériel loué.\n\n'
            '4. Paiements\n'
            'Les paiements doivent être effectués selon les modalités convenues.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de SALAM'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.agriculture, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'SALAM',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Version $_appVersion',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Société Agricole Locale pour l\'Amélioration et la Modernisation',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2025 SALAM\nTous droits réservés',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showTechnicalInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations techniques'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Version', _appVersion),
              _buildInfoRow('API URL', ApiConfig.baseUrl),
              _buildInfoRow('IP Réseau', '192.168.1.23'),
              _buildInfoRow('Réseau', 'MACMILLER (5 GHz)'),
              _buildInfoRow('Vitesse', '468 Mbps'),
              _buildInfoRow('Encodage', 'UTF-8'),
              _buildInfoRow('Framework', 'Flutter'),
              _buildInfoRow('Backend', 'Node.js + PostgreSQL'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide et support'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              Text('📧 Email: dapy@gmail.com'),
              SizedBox(height: 8),
              Text('📱 Téléphone: +221 707 45 87'),
              SizedBox(height: 8),
              Text('🌐 Site web: www.salam-agri.app'),
              SizedBox(height: 16),
              Text(
                'Heures d\'ouverture:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Lun - Ven: 8h00 - 18h00'),
              Text('Sam: 9h00 - 13h00'),
              Text('Dim: Fermé'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await context.read<UserProvider>().logout();
              if (!context.mounted) return;
              // Rediriger vers l'écran de connexion et effacer tout l'historique
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'ATTENTION: Cette action est irréversible.\n\n'
          'Toutes vos données seront supprimées définitivement.\n\n'
          'Voulez-vous vraiment supprimer votre compte ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final userProvider = context.read<UserProvider>();
              navigator.pop();

              // Appel API pour supprimer le compte
              final apiService = ApiService();
              final result = await apiService.deleteAccount();

              if (!mounted) return;

              if (result['success'] == true) {
                _showSuccessSnackBar(
                  result['message'] ?? 'Compte supprimé avec succès',
                );

                // Déconnexion
                await userProvider.logout();

                if (!mounted) return;

                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              } else {
                _showErrorSnackBar(
                  result['message'] ??
                      'Erreur lors de la suppression du compte',
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
