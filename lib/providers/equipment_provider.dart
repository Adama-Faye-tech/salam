import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/equipment_model.dart';
import '../services/supabase_service.dart';

class EquipmentProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  List<Equipment> _equipments = [];
  List<Equipment> _filteredEquipments = [];
  List<Equipment> _services = [];
  bool _isLoading = false;
  String? _error;

  // Filtres
  String? _selectedCategory;
  String? _selectedType;
  double _minPrice = 0;
  double _maxPrice = 500000; // Aligné avec le max du RangeSlider
  double _maxDistance = 100;
  bool _showAvailableOnly = false;
  bool _sortByDistance = false;
  bool _hasLocation = false;

  // Getters
  List<Equipment> get equipments =>
      _filteredEquipments.isNotEmpty ? _filteredEquipments : _equipments;
  List<Equipment> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  String? get selectedType => _selectedType;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get maxDistance => _maxDistance;
  bool get showAvailableOnly => _showAvailableOnly;
  bool get sortByDistance => _sortByDistance;
  bool get hasLocation => _hasLocation;

  // Charger tous les équipements
  Future<void> loadEquipments({
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      var query = _supabase.equipment.select();

      if (category != null) {
        query = query.eq('category', category);
      }
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      final data = await query.order('created_at', ascending: false);
      _equipments = (data as List)
          .map((json) => Equipment.fromJson(json))
          .toList();

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger mes équipements
  Future<void> loadMyEquipments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final data = await _supabase.equipment
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      _equipments = (data as List)
          .map((json) => Equipment.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les services d''un prestataire
  Future<void> loadServicesByProvider(String providerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = await _supabase.equipment
          .select()
          .eq('owner_id', providerId)
          .order('created_at', ascending: false);

      _services = (data as List)
          .map((json) => Equipment.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter un équipement
  Future<bool> addEquipment(Map<String, dynamic> equipmentData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Préparer les données pour Supabase
      final data = {
        'owner_id': userId,
        'title': equipmentData['name'] ?? equipmentData['title'] ?? '',
        'category': equipmentData['category'] ?? '',
        'price':
            (equipmentData['pricePerDay'] ??
                    equipmentData['dailyRate'] ??
                    equipmentData['price'] ??
                    0)
                .toDouble(),
        'description': equipmentData['description'],
        'images': equipmentData['photos'] ?? equipmentData['images'],
        'video_url': equipmentData['videoUrl'],
        'availability': equipmentData['availability'] ?? 'available',
        'location': equipmentData['location'],
        'latitude': equipmentData['latitude'],
        'longitude': equipmentData['longitude'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.equipment.insert(data);
      await loadMyEquipments();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mettre à jour un équipement
  Future<bool> updateEquipment(
    String id,
    Map<String, dynamic> equipmentData,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (equipmentData['name'] != null || equipmentData['title'] != null) {
        updateData['title'] = equipmentData['name'] ?? equipmentData['title'];
      }
      if (equipmentData['category'] != null) {
        updateData['category'] = equipmentData['category'];
      }
      if (equipmentData['description'] != null) {
        updateData['description'] = equipmentData['description'];
      }
      if (equipmentData['pricePerDay'] != null ||
          equipmentData['price'] != null) {
        updateData['price'] =
            (equipmentData['pricePerDay'] ?? equipmentData['price'] as num)
                .toDouble();
      }
      if (equipmentData['isAvailable'] != null ||
          equipmentData['available'] != null) {
        final available =
            equipmentData['isAvailable'] ?? equipmentData['available'];
        updateData['availability'] = available ? 'available' : 'unavailable';
      }
      if (equipmentData['photos'] != null || equipmentData['images'] != null) {
        updateData['images'] =
            equipmentData['photos'] ?? equipmentData['images'];
      }

      await _supabase.equipment.update(updateData).eq('id', id);

      await loadMyEquipments();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Supprimer un équipement
  Future<bool> deleteEquipment(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase.equipment.delete().eq('id', id);

      await loadMyEquipments();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Rechercher des équipements
  Future<void> searchEquipments(String query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final q = query.toLowerCase();

      // Recherche avec Supabase (utilise ilike pour recherche insensible à la casse)
      final data = await _supabase.equipment
          .select()
          .or('title.ilike.%$q%,description.ilike.%$q%')
          .order('created_at', ascending: false);

      _equipments = (data as List)
          .map((json) => Equipment.fromJson(json))
          .toList();

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de recherche: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtenir la localisation de l''utilisateur
  Future<void> getUserLocation() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Permission de localisation refusée';
          _hasLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Permission de localisation refusée définitivement';
        _hasLocation = false;
        notifyListeners();
        return;
      }

      // Obtenir la position actuelle
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Mettre à jour les équipements avec la distance
      if (_equipments.isNotEmpty) {
        final updatedEquipments = _equipments.map((equipment) {
          if (equipment.latitude != null && equipment.longitude != null) {
            final distance =
                Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  equipment.latitude!,
                  equipment.longitude!,
                ) /
                1000; // Convertir en km

            return equipment.copyWith(distance: distance);
          }
          return equipment;
        }).toList();

        _equipments = updatedEquipments;
      }

      _hasLocation = true;
      _applyFilters(); // Ré-appliquer les filtres avec les distances
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de géolocalisation: $e';
      _hasLocation = false;
      notifyListeners();
    }
  }

  // Appliquer les filtres
  void _applyFilters() {
    _filteredEquipments = _equipments.where((equipment) {
      if (_selectedCategory != null &&
          equipment.category != _selectedCategory) {
        return false;
      }

      if (equipment.pricePerDay < _minPrice ||
          equipment.pricePerDay > _maxPrice) {
        return false;
      }

      if (_showAvailableOnly && !equipment.isAvailable) {
        return false;
      }

      if (_maxDistance > 0 &&
          equipment.distance != null &&
          equipment.distance! > _maxDistance) {
        return false;
      }

      return true;
    }).toList();

    if (_sortByDistance && _hasLocation) {
      _filteredEquipments.sort((a, b) {
        final distA = a.distance ?? double.infinity;
        final distB = b.distance ?? double.infinity;
        return distA.compareTo(distB);
      });
    }
  }

  // Setters pour les filtres
  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setTypeFilter(String? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
    notifyListeners();
  }

  void setMaxDistance(double distance) {
    _maxDistance = distance;
    _applyFilters();
    notifyListeners();
  }

  void setAvailableOnly(bool value) {
    _showAvailableOnly = value;
    _applyFilters();
    notifyListeners();
  }

  void toggleSortByDistance() {
    _sortByDistance = !_sortByDistance;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedType = null;
    _minPrice = 0;
    _maxPrice = 1000000;
    _maxDistance = 100;
    _showAvailableOnly = false;
    _sortByDistance = false;
    _applyFilters();
    notifyListeners();
  }
}
