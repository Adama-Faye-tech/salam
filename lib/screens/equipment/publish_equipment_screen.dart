import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/equipment_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../services/api_auth_service.dart';
import '../../services/supabase_service.dart';
import 'package:geolocator/geolocator.dart';

class PublishEquipmentScreen extends StatefulWidget {
  final Equipment? equipment;

  const PublishEquipmentScreen({super.key, this.equipment});

  @override
  State<PublishEquipmentScreen> createState() => _PublishEquipmentScreenState();
}

class _PublishEquipmentScreenState extends State<PublishEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService.instance;
  final ImagePicker _imagePicker = ImagePicker();

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

  // Médias
  final List<File> _photos = [];
  final List<File> _videos = [];

  @override
  void initState() {
    super.initState();
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
    }

    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() => _currentPosition = position);
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

  // Gestion des photos
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _photos.addAll(images.map((xFile) => File(xFile.path)));
        });
        _showSuccessSnackBar('📸 ${images.length} photo(s) ajoutée(s)');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur : $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() => _photos.add(File(photo.path)));
        _showSuccessSnackBar('📸 Photo prise avec succès');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur : $e');
    }
  }

  // Gestion des vidéos
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (video != null) {
        setState(() => _videos.add(File(video.path)));
        _showSuccessSnackBar('🎥 Vidéo ajoutée avec succès');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur : $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      if (video != null) {
        setState(() => _videos.add(File(video.path)));
        _showSuccessSnackBar('🎬 Vidéo enregistrée avec succès');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur : $e');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
    _showSuccessSnackBar('Photo supprimée');
  }

  void _removeVideo(int index) {
    setState(() => _videos.removeAt(index));
    _showSuccessSnackBar('Vidéo supprimée');
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      _showErrorSnackBar('Vous devez être connecté');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final equipmentProvider = context.read<EquipmentProvider>();
      final apiService = ApiService();
      final token = await ApiAuthService.instance.getToken();

      if (token == null || token.isEmpty) {
        _showErrorSnackBar('Session expirée. Veuillez vous reconnecter.');
        setState(() => _isLoading = false);
        // Rediriger vers la page de connexion
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Upload des médias
      List<String> photoUrls = [];
      List<String> videoUrls = [];
      final supabaseService = SupabaseService.instance;

      // Upload des photos
      if (_photos.isNotEmpty) {
        _showSuccessSnackBar('📤 Upload de ${_photos.length} photo(s)...');
        for (var photo in _photos) {
          try {
            // Essayer d'abord l'API REST
            final url = await apiService.uploadImage(photo.path, token);
            if (url != null) {
              photoUrls.add(url);
            } else {
              // Fallback: Upload vers Supabase Storage
              debugPrint('⚠️ API REST échouée, tentative Supabase...');
              final fileName =
                  'equipment_${DateTime.now().millisecondsSinceEpoch}_${photoUrls.length}.jpg';
              final supabaseUrl = await supabaseService.uploadFile(
                bucket: 'equipment',
                path: fileName,
                file: photo,
              );
              photoUrls.add(supabaseUrl);
              debugPrint('✅ Photo uploadée vers Supabase: $supabaseUrl');
            }
          } catch (e) {
            debugPrint('❌ Échec upload photo: $e');
            _showErrorSnackBar('Erreur upload photo: $e');
          }
        }
        _showSuccessSnackBar(
          '✓ ${photoUrls.length}/${_photos.length} photo(s) uploadée(s)',
        );
      }

      // Upload des vidéos
      if (_videos.isNotEmpty) {
        _showSuccessSnackBar('📤 Upload de ${_videos.length} vidéo(s)...');
        for (var video in _videos) {
          try {
            // Essayer d'abord l'API REST
            final url = await apiService.uploadImage(video.path, token);
            if (url != null) {
              videoUrls.add(url);
            } else {
              // Fallback: Upload vers Supabase Storage
              debugPrint('⚠️ API REST échouée, tentative Supabase...');
              final fileName =
                  'equipment_video_${DateTime.now().millisecondsSinceEpoch}_${videoUrls.length}.mp4';
              final supabaseUrl = await supabaseService.uploadFile(
                bucket: 'equipment',
                path: fileName,
                file: video,
              );
              videoUrls.add(supabaseUrl);
              debugPrint('✅ Vidéo uploadée vers Supabase: $supabaseUrl');
            }
          } catch (e) {
            debugPrint('❌ Échec upload vidéo: $e');
            _showErrorSnackBar('Erreur upload vidéo: $e');
          }
        }
        _showSuccessSnackBar(
          '✓ ${videoUrls.length}/${_videos.length} vidéo(s) uploadée(s)',
        );
      }

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
        'photos': photoUrls,
        'videos': videoUrls,
      };

      if (_useCurrentLocation && _currentPosition != null) {
        equipmentData['latitude'] = _currentPosition!.latitude;
        equipmentData['longitude'] = _currentPosition!.longitude;
      } else if (widget.equipment != null) {
        equipmentData['latitude'] = widget.equipment!.latitude;
        equipmentData['longitude'] = widget.equipment!.longitude;
      }

      bool success;
      if (widget.equipment == null) {
        success = await equipmentProvider.addEquipment(equipmentData);
      } else {
        success = await equipmentProvider.updateEquipment(
          widget.equipment!.id,
          equipmentData,
        );
      }

      if (success && mounted) {
        _showSuccessSnackBar(
          widget.equipment == null
              ? '🎉 Équipement publié avec succès !'
              : '✓ Équipement mis à jour',
        );

        if (_photos.isNotEmpty || _videos.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showSuccessSnackBar(
                '📊 ${_photos.length} photo(s) • ${_videos.length} vidéo(s)',
              );
            }
          });
        }

        Navigator.of(context).pop(true);
      } else if (mounted) {
        _showErrorSnackBar(
          equipmentProvider.error ?? '❌ Erreur lors de la sauvegarde',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('❌ Erreur: $e');
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
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
            // Section Informations de base
            _buildSectionTitle(' Informations de base'),
            const SizedBox(height: 12),

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

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Décrivez votre équipement...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Section Prix
            _buildSectionTitle('💰 Tarification'),
            const SizedBox(height: 12),

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
            const SizedBox(height: 24),

            // Section Détails techniques
            _buildSectionTitle('🔧 Détails techniques'),
            const SizedBox(height: 12),

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
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Marque',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Modèle',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.branding_watermark),
              ),
            ),
            const SizedBox(height: 24),

            // Section Localisation
            _buildSectionTitle('📍 Localisation'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Localisation *',
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

            if (_currentPosition != null)
              CheckboxListTile(
                title: const Text('Utiliser ma position actuelle'),
                subtitle: Text(
                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                  'Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _useCurrentLocation,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _useCurrentLocation = value ?? false);
                },
              ),
            const SizedBox(height: 16),

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

            // Section Photos
            _buildSectionTitle(' Photos du matériel'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Caméra'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_photos.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_photos[index], fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}/${_photos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              _buildEmptyMediaCard(
                icon: Icons.photo_camera,
                title: 'Aucune photo ajoutée',
                subtitle: 'Ajoutez des photos pour attirer plus de clients',
              ),
            const SizedBox(height: 24),

            // Section Vidéos
            _buildSectionTitle(' Vidéos du matériel'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library),
                    label: const Text('Galerie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _recordVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Enregistrer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_videos.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_circle_fill, size: 32),
                      ),
                      title: Text(
                        'Vidéo ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _videos[index].path.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeVideo(index),
                      ),
                    ),
                  );
                },
              )
            else
              _buildEmptyMediaCard(
                icon: Icons.videocam,
                title: 'Aucune vidéo ajoutée',
                subtitle:
                    'Les vidéos permettent de mieux présenter le matériel',
              ),
            const SizedBox(height: 24),

            // Info si pas de médias
            if (_photos.isEmpty && _videos.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ajoutez des photos et vidéos pour augmenter la visibilité !',
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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
                        : Text(
                            widget.equipment == null
                                ? 'Publier'
                                : 'Mettre à jour',
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyMediaCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
