import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'my_orders_screen.dart';
import 'provider_orders_screen.dart';

/// Écran routeur qui affiche le bon écran de commandes selon le rôle
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    
    // Si non connecté, afficher page de connexion
    if (!userProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes Commandes'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Connectez-vous pour voir vos commandes',
                style: TextStyle(
                  fontSize: 18,
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
    
    // Router selon le rôle
    final user = userProvider.currentUser!;
    
    if (user.userType == UserType.provider) {
      // Prestataire : afficher les demandes reçues
      return const ProviderOrdersScreen();
    } else {
      // Agriculteur : afficher mes réservations
      return const MyOrdersScreen();
    }
  }
}


