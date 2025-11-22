import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/equipment_card.dart';
import '../equipment/equipment_detail_screen.dart';
import '../auth/login_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    
    // Si non connecté, afficher message de connexion
    if (!userProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes Favoris'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Connectez-vous pour voir vos favoris',
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favProvider, _) {
              if (favProvider.totalFavorites == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer tous les favoris'),
                      content: const Text('Étes-vous sûr de vouloir supprimer tous vos favoris ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Non'),
                        ),
                        TextButton(
                          onPressed: () {
                            favProvider.clearAllFavorites();
                            Navigator.pop(context);
                          },
                          child: const Text('Oui', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Tout supprimer'),
              );
            },
          ),
        ],
      ),
      body: Consumer2<FavoritesProvider, EquipmentProvider>(
        builder: (context, favProvider, equipmentProvider, _) {
          if (favProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favProvider.totalFavorites == 0) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun favori'),
                  SizedBox(height: 8),
                  Text(
                    'Ajoutez des matériels à vos favoris pour les retrouver ici',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Récupérer les équipements favoris
          final favoriteEquipments = equipmentProvider.equipments
              .where((eq) => favProvider.isEquipmentFavorite(eq.id))
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favoriteEquipments.length,
            itemBuilder: (context, index) {
              final equipment = favoriteEquipments[index];
              return EquipmentCard(
                equipment: equipment,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EquipmentDetailScreen(equipment: equipment),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


