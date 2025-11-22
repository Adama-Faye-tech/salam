import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/filter_chip_widget.dart';
import '../../config/constants.dart';
import '../equipment/equipment_detail_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  Timer? _searchDebounce;

  // Liste des bannières avec images et textes
  final List<Map<String, String>> promotions = [
    {
      'title': 'Réduction de 20% sur tous les tracteurs !',
      'image': 'assets/images/Gemini_Generated_Image_glr0tlglr0tlglr0.png',
    },
    {
      'title': 'Nouveaux prestataires disponibles',
      'image': 'assets/images/Gemini_Generated_Image_p7dpstp7dpstp7dp.png',
    },
    {
      'title': 'Service de moisson : Offre spéciale',
      'image': 'assets/images/Gemini_Generated_Image_glr0tlglr0tlglr0.png',
    },
    {
      'title': 'Bienvenue sur SAME - Location d\'équipements agricoles',
      'image': 'assets/images/Gemini_Generated_Image_p7dpstp7dpstp7dp.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final equipmentProvider = context.read<EquipmentProvider>();
      final userProvider = context.read<UserProvider>();
      final notificationsProvider = context.read<NotificationsProvider>();

      equipmentProvider.loadEquipments();

      if (userProvider.currentUser != null) {
        notificationsProvider.loadNotifications(userProvider.currentUser!.id);
      }

      // Démarrer le défilement automatique
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.round() ?? 0) + 1;
        if (nextPage >= promotions.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<EquipmentProvider>().loadEquipments();
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverToBoxAdapter(child: _buildFilterChips()),
                    SliverToBoxAdapter(child: _buildPromotionsBanner()),
                    SliverToBoxAdapter(
                      child: _buildSectionTitle('Matériels disponibles'),
                    ),
                    _buildEquipmentGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer3<UserProvider, NotificationsProvider, EquipmentProvider>(
      builder:
          (context, userProvider, notificationsProvider, equipmentProvider, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton de géolocalisation
                  IconButton(
                    icon: Icon(
                      equipmentProvider.hasLocation
                          ? Icons.location_on
                          : Icons.location_off,
                      color: equipmentProvider.hasLocation
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      size: 22,
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      if (!equipmentProvider.hasLocation) {
                        await equipmentProvider.getUserLocation();
                        if (!mounted) return;

                        if (equipmentProvider.hasLocation) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Position obtenue'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Impossible de récupérer la position',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Position déjà activée'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),

                  // Titre centré
                  Text(
                    'SAME',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  // Notifications
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 22,
                        ),
                        onPressed: () {
                          if (userProvider.isAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          } else {
                            // Afficher un message si non connecté
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Connectez-vous pour voir vos notifications',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      if (userProvider.isAuthenticated &&
                          notificationsProvider.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${notificationsProvider.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un matériel...',
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: _showFilterBottomSheet,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          // Annuler le timer précédent
          _searchDebounce?.cancel();

          // Lancer un nouveau timer (debounce de 500ms)
          _searchDebounce = Timer(const Duration(milliseconds: 500), () {
            final equipmentProvider = context.read<EquipmentProvider>();
            final query = value.trim();
            if (query.isNotEmpty) {
              equipmentProvider.searchEquipments(query);
            } else {
              equipmentProvider.loadEquipments();
            }
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              // Filtre "À proximité"
              if (provider.hasLocation)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 16,
                          color: provider.sortByDistance
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        const Text('À proximité'),
                      ],
                    ),
                    selected: provider.sortByDistance,
                    onSelected: (_) {
                      provider.toggleSortByDistance();
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: provider.sortByDistance
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: provider.sortByDistance
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              FilterChipWidget(
                label: 'Tous',
                isSelected: provider.selectedCategory == null,
                onSelected: (selected) {
                  if (selected) provider.setCategoryFilter(null);
                },
              ),
              ...AppConstants.equipmentCategories.map(
                (category) => FilterChipWidget(
                  label: category,
                  isSelected: provider.selectedCategory == category,
                  onSelected: (selected) {
                    provider.setCategoryFilter(selected ? category : null);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromotionsBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final promo = promotions[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image de fond
                        Image.asset(
                          promo['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Image par défaut si l'image n'est pas trouvée
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.agriculture,
                                size: 60,
                                color: Colors.white70,
                              ),
                            );
                          },
                        ),
                        // Overlay gradient pour améliorer la lisibilité du texte
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                        // Texte par dessus
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              promo['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          SmoothPageIndicator(
            controller: _pageController,
            count: promotions.length,
            effect: WormEffect(
              dotHeight: 6,
              dotWidth: 6,
              activeDotColor: Theme.of(context).primaryColor,
              dotColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Consumer<EquipmentProvider>(
            builder: (context, provider, _) {
              if (provider.selectedCategory != null ||
                  provider.selectedType != null ||
                  provider.showAvailableOnly) {
                return TextButton(
                  onPressed: () {
                    provider.clearFilters();
                  },
                  child: const Text('Réinitialiser'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentGrid() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.equipments.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun matériel disponible'),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72, // Hauteur réduite
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final equipment = provider.equipments[index];
              return EquipmentCard(
                equipment: equipment,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EquipmentDetailScreen(equipment: equipment),
                    ),
                  );
                },
              );
            }, childCount: provider.equipments.length),
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<EquipmentProvider>(
          builder: (context, provider, _) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filtres',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            TextButton(
                              onPressed: () {
                                provider.clearFilters();
                                Navigator.pop(context);
                              },
                              child: const Text('Réinitialiser'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Prix par jour (FCFA)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        RangeSlider(
                          values: RangeValues(
                            provider.minPrice,
                            provider.maxPrice,
                          ),
                          min: 0,
                          max: 500000,
                          divisions: 100,
                          labels: RangeLabels(
                            '${provider.minPrice.toInt()}',
                            '${provider.maxPrice.toInt()}',
                          ),
                          onChanged: (values) {
                            provider.setPriceRange(values.start, values.end);
                          },
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Distance maximale (km)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: provider.maxDistance,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          label: '${provider.maxDistance.toInt()} km',
                          onChanged: (value) {
                            provider.setMaxDistance(value);
                          },
                        ),

                        const SizedBox(height: 24),

                        SwitchListTile(
                          title: const Text(
                            'Afficher uniquement les disponibles',
                          ),
                          value: provider.showAvailableOnly,
                          onChanged: (value) {
                            provider.setAvailableOnly(value);
                          },
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Appliquer les filtres'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
