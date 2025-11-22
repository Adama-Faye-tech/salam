import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/equipment_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/user_provider.dart';
import '../config/theme.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const EquipmentCard({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'fr_FR');

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge disponibilité et bouton favori
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: equipment.photos.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: equipment.photos.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: const Icon(Icons.agriculture, size: 50),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.agriculture, size: 50),
                        ),
                ),

                // Badge disponibilité
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: equipment.isAvailable
                          ? AppColors.success
                          : AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      equipment.isAvailable ? 'Disponible' : 'Indisponible',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Bouton favori
                Positioned(
                  top: 6,
                  right: 6,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favProvider, _) {
                      final isFavorite = favProvider.isEquipmentFavorite(
                        equipment.id,
                      );
                      return InkWell(
                        onTap: () {
                          favProvider.toggleEquipmentFavorite(equipment.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.favorite
                                : Colors.grey,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Informations
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    equipment.category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(
                        equipment.distance != null
                            ? Icons.near_me
                            : Icons.location_on,
                        size: 11,
                        color: equipment.distance != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 1),
                      Expanded(
                        child: Text(
                          equipment.distance != null
                              ? LocationService.instance.formatDistance(
                                  equipment.distance!,
                                )
                              : equipment.location,
                          style: TextStyle(
                            color: equipment.distance != null
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: equipment.distance != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${numberFormat.format(equipment.pricePerDay)} FCFA/jour',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Bouton Discuter avec le prestataire
                  SizedBox(
                    width: double.infinity,
                    height: 24,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Ouvrir une conversation avec le prestataire
                        _openChatWithProvider(context, equipment);
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 12),
                      label: const Text(
                        'Discuter',
                        style: TextStyle(fontSize: 10),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithProvider(BuildContext context, Equipment equipment) {
    // Vérifier si l'utilisateur est connecté
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      // Rediriger vers la page de connexion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez vous connecter pour discuter avec un prestataire',
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigation vers l'écran de connexion
      Navigator.pushNamed(context, '/login');
      return;
    }

    // Si connecté, ouvrir le chat
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'providerId': equipment.providerId,
        'providerName': equipment.providerName,
        'equipmentId': equipment.id,
        'equipmentName': equipment.name,
      },
    );
  }
}
