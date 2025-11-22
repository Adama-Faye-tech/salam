import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/supabase_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await SupabaseService.instance.resetPassword(email);

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Message d'information important
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Demande envoyée'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Un email a été envoyé à :\n$email'),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ IMPORTANT :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Vérifiez votre boîte de réception\n'
                  '• Vérifiez aussi le dossier SPAM\n'
                  '• L\'email peut prendre 2-5 min\n'
                  '• Si rien après 10 min, le compte n\'existe peut-être pas',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                const Text(
                  '💡 Solution alternative :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si vous ne recevez rien, créez un NOUVEAU compte avec "Créer un compte"',
                  style: TextStyle(fontSize: 13, color: Colors.orange[700]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
                Navigator.of(context).pop(); // Retour à login
              },
              child: const Text('Compris'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      // Message d'erreur détaillé
      String errorMessage = 'Erreur lors de l\'envoi de l\'email';

      if (e.toString().toLowerCase().contains('rate limit')) {
        errorMessage =
            'Trop de tentatives. Veuillez attendre quelques minutes.';
      } else if (e.toString().toLowerCase().contains('network')) {
        errorMessage = 'Problème de connexion réseau.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Erreur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              const SizedBox(height: 16),
              const Text(
                '💡 Solution :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Vérifiez votre connexion internet\n'
                '2. Attendez quelques minutes\n'
                '3. Ou créez un nouveau compte',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié'), elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_reset, size: 60, color: AppColors.primary),
                    const SizedBox(height: 24),
                    Text(
                      'Réinitialiser le mot de passe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Entrez votre email pour recevoir un lien de réinitialisation',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!value.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Envoyer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
