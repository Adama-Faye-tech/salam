import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../models/equipment_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
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
  final _imagePicker = ImagePicker();

  // Limites de médias
  static const int maxPhotos = 15;
  static const int maxVideos = 15;

  // Médias sélectionnés
  List<XFile> _selectedPhotos = [];
  List<XFile> _selectedVideos = [];

  // URLs des médias existants (pour l'édition)
  List<String> _existingPhotos = [];
  List<String> _existingVideos = [];

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
      _existingPhotos = List.from(widget.equipment!.photos);
      _existingVideos = List.from(widget.equipment!.videos);
    }

    // Charger la position actuelle
    _loadCurrentPosition();
  }

  // Méthodes de gestion des médias
  Future<void> _pickImages() async {
    if (_selectedPhotos.length + _existingPhotos.length >= maxPhotos) {
      _showMessage('Vous avez atteint la limite de $maxPhotos photos');
      return;
    }

    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          final remaining =
              maxPhotos - _selectedPhotos.length - _existingPhotos.length;
          _selectedPhotos.addAll(images.take(remaining));
        });
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection des photos: $e');
    }
  }

  Future<void> _pickVideos() async {
    if (_selectedVideos.length + _existingVideos.length >= maxVideos) {
      _showMessage('Vous avez atteint la limite de $maxVideos vidéos');
      return;
    }

    try {
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          if (_selectedVideos.length + _existingVideos.length < maxVideos) {
            _selectedVideos.add(video);
          }
        });
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection de la vidéo: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotos.removeAt(index);
    });
  }

  void _removeExistingVideo(int index) {
    setState(() {
      _existingVideos.removeAt(index);
    });
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<List<String>> _uploadMedia(List<XFile> files, String folder) async {
    final List<String> urls = [];
    final supabase = SupabaseService.instance.client;

    for (var file in files) {
      try {
        final bytes = await file.readAsBytes();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final path = '$folder/$fileName';

        await supabase.storage.from('equipment').uploadBinary(path, bytes);
        final url = supabase.storage.from('equipment').getPublicUrl(path);
        urls.add(url);
      } catch (e) {
        debugPrint('Erreur upload $folder: $e');
      }
    }

    return urls;
  }

  Future<void> _loadCurrentPosition() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
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
      // Upload des nouveaux médias
      final newPhotoUrls = await _uploadMedia(_selectedPhotos, 'photos');
      final newVideoUrls = await _uploadMedia(_selectedVideos, 'videos');

      // Combiner avec les médias existants
      final allPhotos = [..._existingPhotos, ...newPhotoUrls];
      final allVideos = [..._existingVideos, ...newVideoUrls];

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
        'photos': allPhotos,
        'videos': allVideos,
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

            // Section médias
            _buildMediaSection(),
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

  Widget _buildMediaSection() {
    final totalPhotos = _selectedPhotos.length + _existingPhotos.length;
    final totalVideos = _selectedVideos.length + _existingVideos.length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Photos et Vidéos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Boutons d'ajout
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text('Photos ($totalPhotos/$maxPhotos)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickVideos,
                    icon: const Icon(Icons.videocam),
                    label: Text('Vidéos ($totalVideos/$maxVideos)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Photos existantes
            if (_existingPhotos.isNotEmpty) ...[
              const Text(
                'Photos actuelles:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildExistingMediaGrid(_existingPhotos, true),
              const SizedBox(height: 16),
            ],

            // Nouvelles photos
            if (_selectedPhotos.isNotEmpty) ...[
              const Text(
                'Nouvelles photos:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              _buildNewMediaGrid(_selectedPhotos, true),
              const SizedBox(height: 16),
            ],

            // Vidéos existantes
            if (_existingVideos.isNotEmpty) ...[
              const Text(
                'Vidéos actuelles:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildExistingMediaGrid(_existingVideos, false),
              const SizedBox(height: 16),
            ],

            // Nouvelles vidéos
            if (_selectedVideos.isNotEmpty) ...[
              const Text(
                'Nouvelles vidéos:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              _buildNewMediaGrid(_selectedVideos, false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExistingMediaGrid(List<String> urls, bool isPhoto) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls.asMap().entries.map((entry) {
        final index = entry.key;
        final url = entry.value;

        return Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isPhoto
                    ? Image.network(url, fit: BoxFit.cover)
                    : Container(
                        color: Colors.black87,
                        child: const Icon(
                          Icons.play_circle_outline,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => isPhoto
                    ? _removeExistingPhoto(index)
                    : _removeExistingVideo(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNewMediaGrid(List<XFile> files, bool isPhoto) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: files.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;

        return Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isPhoto
                    ? FutureBuilder<Uint8List>(
                        future: file.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      )
                    : Container(
                        color: Colors.black87,
                        child: const Icon(
                          Icons.play_circle_outline,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () =>
                    isPhoto ? _removePhoto(index) : _removeVideo(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
