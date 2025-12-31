import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment_model.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class EquipmentProvider with ChangeNotifier {
  List<Equipment> _equipments = [];
  List<Equipment> _filteredEquipments = [];
  List<Equipment> _services = [];
  bool _isLoading = false;
  String? _error;

  // Filtres
  String? _selectedCategory;
  String? _selectedType;
  double _minPrice = 0;
  double _maxPrice = 500000;
  double _maxDistance = 100;
  bool _showAvailableOnly = false;
  bool _sortByDistance = false;
  bool _hasLocation = false;

  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  static const int _pageSize = 20;

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
  bool get hasMore => _hasMore;

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

      Query query = FirestoreService.equipment;

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      final snapshot = await query
          .orderBy('created_at', descending: true)
          .get();
      _equipments = snapshot.docs
          .map(
            (doc) => Equipment.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
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

      final userId = FirebaseAuthService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final snapshot = await FirestoreService.equipment
          .where('owner_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      _equipments = snapshot.docs
          .map(
            (doc) => Equipment.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les services d'un prestataire
  Future<void> loadServicesByProvider(String providerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await FirestoreService.equipment
          .where('owner_id', isEqualTo: providerId)
          .orderBy('created_at', descending: true)
          .get();

      _services = snapshot.docs
          .map(
            (doc) => Equipment.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
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

      final userId = FirebaseAuthService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Préparer les données pour Firestore
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
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirestoreService.equipment.add(data);
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
        'updated_at': FieldValue.serverTimestamp(),
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

      await FirestoreService.equipment.doc(id).update(updateData);

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

      await FirestoreService.equipment.doc(id).delete();

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

      // Firestore n'a pas de recherche full-text native
      // On charge tous les équipements et on filtre côté client
      final snapshot = await FirestoreService.equipment
          .orderBy('created_at', descending: true)
          .get();

      final q = query.toLowerCase();
      _equipments = snapshot.docs
          .map(
            (doc) => Equipment.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .where((equipment) {
            final title = equipment.name.toLowerCase();
            final description = equipment.description.toLowerCase();
            return title.contains(q) || description.contains(q);
          })
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

  // Obtenir la localisation de l'utilisateur
  Future<void> getUserLocation() async {
    // Géolocalisation désactivée dans la version simplifiée
    _hasLocation = false;
    notifyListeners();
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

  /// PAGINATION: Charger plus d'équipements
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      Query query = FirestoreService.equipment;

      if (_selectedCategory != null) {
        query = query.where('category', isEqualTo: _selectedCategory);
      }

      query = query.orderBy('created_at', descending: true).limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = snapshot.docs.last;
        
        final newEquipments = snapshot.docs
            .map(
              (doc) => Equipment.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();

        _equipments.addAll(newEquipments);
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// REAL-TIME: Stream pour écouter les changements en temps réel
  Stream<List<Equipment>> watchEquipments({
    String? category,
  }) {
    Query query = FirestoreService.equipment;

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('created_at', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Equipment.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    });
  }

  /// Réinitialiser la pagination
  void resetPagination() {
    _lastDocument = null;
    _hasMore = true;
    _equipments.clear();
    _filteredEquipments.clear();
  }
}
