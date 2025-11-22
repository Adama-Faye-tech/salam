import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment_model.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/user_provider.dart';
import 'new_equipment_screen.dart';

class MyEquipmentScreen extends StatefulWidget {
  const MyEquipmentScreen({super.key});

  @override
  State<MyEquipmentScreen> createState() => _MyEquipmentScreenState();
}

class _MyEquipmentScreenState extends State<MyEquipmentScreen> {
  bool _isLoading = true;
  List<Equipment> _myEquipments = [];

  @override
  void initState() {
    super.initState();
    _loadMyEquipments();
  }

  Future<void> _loadMyEquipments() async {
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final equipmentProvider = context.read<EquipmentProvider>();

  // Charger tous les équipements
    await equipmentProvider.loadEquipments();

  // Filtrer ceux qui appartiennent à l'utilisateur
    if (userProvider.currentUser != null) {
      _myEquipments = equipmentProvider.equipments
          .where((eq) => eq.providerId == userProvider.currentUser!.id.toString())
          .toList();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleAvailability(Equipment equipment) async {
    final equipmentProvider = context.read<EquipmentProvider>();
    final success = await equipmentProvider.updateEquipment(
      equipment.id,
      {'available': !equipment.isAvailable},
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            equipment.isAvailable
                ? 'Équipement masqué'
                : 'Équipement visible',
          ),
        ),
      );
      _loadMyEquipments();
    }
  }

  Future<void> _deleteEquipment(Equipment equipment) async {
    final equipmentProvider = context.read<EquipmentProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${equipment.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await equipmentProvider.deleteEquipment(equipment.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Équipement supprimé')),
        );
        _loadMyEquipments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue lors de la suppression'),
          ),
        );
      }
    }
  }

  Future<void> _editEquipment(Equipment equipment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewEquipmentScreen(equipment: equipment),
      ),
    );

    if (result == true) {
      _loadMyEquipments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Mes équipements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyEquipments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myEquipments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMyEquipments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myEquipments.length,
                    itemBuilder: (context, index) {
                      final equipment = _myEquipments[index];
                      return _buildEquipmentCard(equipment);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewEquipmentScreen(),
            ),
          );
          if (result == true) {
            _loadMyEquipments();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun équipement publié',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par publier votre premier équipement',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewEquipmentScreen(),
                ),
              );
              if (result == true) {
                _loadMyEquipments();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Publier un équipement'),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (equipment.photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              child: Image.network(
                equipment.photos.first,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.agriculture, size: 60),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        equipment.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: equipment.isAvailable
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        equipment.isAvailable ? '✅ Visible' : 'Équipement masqué',
                        style: TextStyle(
                          fontSize: 12,
                          color: equipment.isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Catégorie
                Text(
                  equipment.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Prix
                Row(
                  children: [
                    if (equipment.pricePerHour > 0) ...[
                      Text(
                        '${equipment.pricePerHour.toStringAsFixed(0)} FCFA/h',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      '${equipment.pricePerDay.toStringAsFixed(0)} FCFA/jour',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Infos supplémentaires
                if (equipment.year.isNotEmpty || equipment.model != null)
                  Text(
                    [
                      if (equipment.brand != null) equipment.brand,
                      if (equipment.model != null) equipment.model,
                      if (equipment.year.isNotEmpty) equipment.year,
                    ].join(' • '),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 12),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editEquipment(equipment),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleAvailability(equipment),
                        icon: Icon(
                          equipment.isAvailable
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                        ),
                        label: Text(equipment.isAvailable ? 'Masquer' : 'Afficher'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteEquipment(equipment),
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


