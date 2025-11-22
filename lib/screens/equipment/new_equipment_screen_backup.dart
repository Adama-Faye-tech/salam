import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../models/equipment_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class NewEquipmentScreen extends StatefulWidget {
  final Equipment? equipment; // Pour l'édition

  const NewEquipmentScreen({super.key, this.equipment});

  @override
  State<NewEquipmentScreen> createState() => _NewEquipmentScreenState();
}

class _NewEquipmentScreenState extends State<NewEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService.instance;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _pricePerHourController;
  late TextEditingController _pricePerDayController;
  late TextEditingController _yearController;
  late TextEditingController _modelController;
  late TextEditingController _brandController;
  late TextEditingController _locationController;
  late TextEditingController _interventionZoneController;

  // State
  String _selectedCategory = AppConstants.equipmentCategories.first;
  bool _isLoading = false;
  Position? _currentPosition;
  bool _useCurrentLocation = false;
  final List<String> _selectedPhotos = []; // Chemins des photos sélectionnées
  List<String> _existingPhotos =
      []; // URLs des photos existantes (pour édition)

  @override
  void initState() {
    super.initState();
    // Initialiser les controllers avec les données existantes si édition
    _nameController = TextEditingController(text: widget.equipment?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.equipment?.description ?? '',
    );
    _pricePerHourController = TextEditingController(
      text: widget.equipment?.pricePerHour.toString() ?? '0',
    );
    _pricePerDayController = TextEditingController(
      text: widget.equipment?.pricePerDay.toString() ?? '',
    );
    _yearController = TextEditingController(text: widget.equipment?.year ?? '');
    _modelController = TextEditingController(
      text: widget.equipment?.model ?? '',
    );
    _brandController = TextEditingController(
      text: widget.equipment?.brand ?? '',
    );
    _locationController = TextEditingController(
      text: widget.equipment?.location ?? '',
    );
    _interventionZoneController = TextEditingController(
      text: widget.equipment?.interventionZone ?? '',
    );

    if (widget.equipment != null) {
      _selectedCategory = widget.equipment!.category;
      _existingPhotos = List<String>.from(widget.equipment!.photos);
    }

    // Charger la position actuelle
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);

      if (images.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(images.map((img) => img.path));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length} photo(s) ajoutée(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotos.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pricePerHourController.dispose();
    _pricePerDayController.dispose();
    _yearController.dispose();
    _modelController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    _interventionZoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vous devez être connecté')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final equipmentProvider = context.read<EquipmentProvider>();

      final equipmentData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': 'materiel',
        'category': _selectedCategory,
        'pricePerHour':
            double.tryParse(_pricePerHourController.text.trim()) ?? 0,
        'pricePerDay': double.parse(_pricePerDayController.text.trim()),
        'year': _yearController.text.trim(),
        'model': _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        'brand': _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        'location': _locationController.text.trim(),
        'interventionZone': _interventionZoneController.text.trim(),
        'photos': [..._existingPhotos, ..._selectedPhotos],
        'videos': <String>[],
      };

      // Ajouter les coordonnées GPS si disponibles
      if (_useCurrentLocation && _currentPosition != null) {
        equipmentData['latitude'] = _currentPosition!.latitude;
        equipmentData['longitude'] = _currentPosition!.longitude;
      } else if (widget.equipment != null) {
        equipmentData['latitude'] = widget.equipment!.latitude;
        equipmentData['longitude'] = widget.equipment!.longitude;
      }

      bool success;
      if (widget.equipment == null) {
        // Création
        success = await equipmentProvider.addEquipment(equipmentData);
      } else {
        // Mise àƒ  jour
        success = await equipmentProvider.updateEquipment(
          widget.equipment!.id,
          equipmentData,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.equipment == null
                  ? ' Équipement publié avec succès'
                  : ' Équipement mis à jour',
            ),
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              equipmentProvider.error ?? 'Erreur lors de la sauvegarde',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.equipment == null
              ? 'Publier un équipement'
              : 'Modifier l\'équipement',
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'équipement *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.agriculture),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Catégorie
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: AppConstants.equipmentCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Prix
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pricePerHourController,
                    decoration: const InputDecoration(
                      labelText: 'Prix/heure (FCFA)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pricePerDayController,
                    decoration: const InputDecoration(
                      labelText: 'Prix/jour (FCFA) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Prix requis';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Prix invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Année, Modèle, Marque
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Modèle',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marque',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.branding_watermark),
              ),
            ),
            const SizedBox(height: 16),

            // Localisation
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Localisation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La localisation est requise';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Option GPS
            if (_currentPosition != null)
              CheckboxListTile(
                title: const Text('Utiliser ma position actuelle'),
                subtitle: Text(
                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                  'Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _useCurrentLocation,
                onChanged: (value) {
                  setState(() => _useCurrentLocation = value ?? false);
                },
              ),
            const SizedBox(height: 16),

            // Zone d'intervention
            TextFormField(
              controller: _interventionZoneController,
              decoration: const InputDecoration(
                labelText: 'Zone d\'intervention',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
                hintText: 'Ex: Dakar, Thiès, Kaolack',
              ),
            ),
            const SizedBox(height: 24),

            // Photos
            _buildPhotosSection(),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.equipment == null
                                ? 'Publier'
                                : 'Mettre àƒ  jour',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    final totalPhotos = _existingPhotos.length + _selectedPhotos.length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Photos ($totalPhotos)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            if (totalPhotos > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingPhotos.length + _selectedPhotos.length,
                  itemBuilder: (context, index) {
                    final isExisting = index < _existingPhotos.length;
                    final photoIndex = isExisting
                        ? index
                        : index - _existingPhotos.length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isExisting
                                  ? Image.network(
                                      _existingPhotos[photoIndex],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    )
                                  : Image.file(
                                      File(_selectedPhotos[photoIndex]),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed: () {
                                  if (isExisting) {
                                    _removeExistingPhoto(photoIndex);
                                  } else {
                                    _removePhoto(photoIndex);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune photo ajoutée',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ajoutez des photos de votre équipement',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
