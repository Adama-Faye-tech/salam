import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/equipment_model.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/media_carousel.dart';
import '../../config/api_config.dart';
import '../chat/chat_screen.dart';
import '../auth/login_screen.dart';
import '../orders/booking_screen.dart';
import '../profile/user_profile_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Charger les équipements du prestataire sera fait via Consumer dans _buildProviderServices
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(),
                _buildMainInfo(currencyFormat),
                _buildDescription(),
                _buildTechnicalSpecs(),
                _buildProviderInfo(),
                _buildProviderServices(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(currencyFormat),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            final isFavorite = favoritesProvider.isEquipmentFavorite(
              widget.equipment.id,
            );
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black,
              ),
              onPressed: () {
                favoritesProvider.toggleEquipmentFavorite(widget.equipment.id);
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black),
          onPressed: () async {
            final equipment = widget.equipment;
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final shareText =
                '''
🚜 ${equipment.name}
💰 ${equipment.pricePerDay} FCFA/jour
📍 ${equipment.location}

${equipment.description}

🔗 Voir sur SAME - Plateforme de location d'équipements agricoles
''';

            try {
              await Share.share(
                shareText,
                subject: 'Équipement: ${equipment.name}',
              );
            } catch (e) {
              if (context.mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors du partage'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    return MediaCarousel(
      photos: widget.equipment.photos,
      videos: widget.equipment.videos,
      height: 350,
      showIndicator: true,
    );
  }

  Widget _buildMainInfo(NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.equipment.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.equipment.isAvailable
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.equipment.isAvailable ? 'Disponible' : 'Indisponible',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.equipment.category,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.equipment.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
              if (widget.equipment.distance != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${widget.equipment.distance!.toStringAsFixed(1)} km',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.equipment.pricePerHour > 0) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix horaire',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(widget.equipment.pricePerHour)}/h',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.equipment.pricePerDay > 0) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix journalier',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(widget.equipment.pricePerDay)}/jour',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.equipment.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caractéristiques techniques',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Année', widget.equipment.year),
          _buildSpecRow('Modèle', widget.equipment.model ?? 'N/A'),
          _buildSpecRow('Marque', widget.equipment.brand ?? 'N/A'),
          _buildSpecRow(
            'Zone d\'intervention',
            widget.equipment.interventionZone,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prestataire',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: widget.equipment.providerPhoto != null
                    ? CachedNetworkImageProvider(
                        '${ApiConfig.baseUrl}${widget.equipment.providerPhoto}',
                      )
                    : null,
                child: widget.equipment.providerPhoto == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.equipment.providerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.equipment.providerRating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.equipment.providerRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: widget.equipment.providerId,
                        userName: widget.equipment.providerName,
                        userPhotoUrl: widget.equipment.providerPhoto,
                        rating: widget.equipment.providerRating,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Voir profil'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderServices() {
    return Consumer<EquipmentProvider>(
      builder: (context, equipmentProvider, child) {
        // Filtrer les équipements du même prestataire
        final otherServices = equipmentProvider.equipments
            .where(
              (e) =>
                  e.providerId == widget.equipment.providerId &&
                  e.id != widget.equipment.id,
            )
            .toList();

        if (otherServices.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Autres services du prestataire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: otherServices.length,
                  itemBuilder: (context, index) {
                    final equipment = otherServices[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EquipmentDetailScreen(equipment: equipment),
                          ),
                        );
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: equipment.photos.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          '${ApiConfig.baseUrl}${equipment.photos[0]}',
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error),
                                          ),
                                    )
                                  : Container(
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    equipment.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${equipment.pricePerDay} FCFA/jour',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À partir de',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    widget.equipment.pricePerHour > 0
                        ? '${currencyFormat.format(widget.equipment.pricePerHour)}/h'
                        : '${currencyFormat.format(widget.equipment.pricePerDay)}/jour',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contacter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: widget.equipment.isAvailable ? _openBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text('Réserver'),
            ),
          ],
        ),
      ),
    );
  }

  void _openBooking() {
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
        builder: (context) => BookingScreen(equipment: widget.equipment),
      ),
    );
  }

  void _openChat() {
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
          providerId: widget.equipment.providerId,
          providerName: widget.equipment.providerName,
          providerAvatar: widget.equipment.providerPhoto,
        ),
      ),
    );
  }
}
