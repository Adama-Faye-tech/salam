import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Service de gàƒÆ’à‚©olocalisation pour obtenir la position de l'utilisateur
/// et calculer les distances
class LocationService {
  static final LocationService instance = LocationService._internal();
  factory LocationService() => instance;
  LocationService._internal();

  Position? _currentPosition;
  DateTime? _lastUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Obtenir la position actuelle de l'utilisateur
  Position? get currentPosition => _currentPosition;

  /// VàƒÆ’à‚©rifier si les services de localisation sont activàƒÆ’à‚©s
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// VàƒÆ’à‚©rifier les permissions de localisation
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Demander les permissions de localisation
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Obtenir la position actuelle avec gestion des permissions et erreurs
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    try {
      // Si on a une position en cache et qu'elle n'est pas expiràƒÆ’à‚©e
      if (!forceRefresh &&
          _currentPosition != null &&
          _lastUpdate != null &&
          DateTime.now().difference(_lastUpdate!) < _cacheTimeout) {
        debugPrint('Position en cache utilisée');
        return _currentPosition;
      }

      // VàƒÆ’à‚©rifier si le service de localisation est activàƒÆ’à‚©
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Service de localisation désactivé');
        return null;
      }

      // VàƒÆ’à‚©rifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Permission de localisation refusée');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          '❌ Permission de localisation refusée définitivement',
        );
        return null;
      }

      // Obtenir la position
      debugPrint('📍 Obtention de la position...');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastUpdate = DateTime.now();
      debugPrint(
        'â✓¬¦ Position obtenue: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
      return _currentPosition;
    } catch (e) {
      debugPrint('❌ Erreur obtention position: $e');
      return null;
    }
  }

  /// Calculer la distance entre deux points GPS en kilomàƒÆ’à‚¨tres
  /// Utilise la formule de Haversine pour un calcul pràƒÆ’à‚©cis sur une sphàƒÆ’à‚¨re
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    // Convertir en radians
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double lat1Rad = _toRadians(lat1);
    double lat2Rad = _toRadians(lat2);

    // Formule de Haversine
    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1Rad) *
            math.cos(lat2Rad);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  /// Calculer la distance depuis la position actuelle vers un point
  double? calculateDistanceFromCurrent(double lat, double lon) {
    if (_currentPosition == null) return null;

    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    );
  }

  /// Formater une distance pour l'affichage
  /// < 1 km: affiche en màƒÆ’à‚¨tres
  /// >= 1 km: affiche en kilomàƒÆ’à‚¨tres avec 1 dàƒÆ’à‚©cimale
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Obtenir un message d'erreur convivial selon le type de permission
  String getPermissionErrorMessage(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Permission de localisation refusée. Veuillez l\'activer dans les paramètres.';
      case LocationPermission.deniedForever:
        return 'Permission de localisation refusée définitivement. Veuillez l\'activer manuellement dans les paramètres de l\'appareil.';
      case LocationPermission.unableToDetermine:
        return 'Impossible de déterminer les permissions de localisation.';
      default:
        return 'Erreur de localisation inconnue.';
    }
  }

  /// Ouvrir les paramàƒÆ’à‚¨tres de l'application pour que l'utilisateur active la localisation
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Ouvrir les paramàƒÆ’à‚¨tres de l'application
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// RàƒÆ’à‚©initialiser le cache de position
  void clearCache() {
    _currentPosition = null;
    _lastUpdate = null;
    debugPrint('🗑 Cache de position vidée');
  }

  /// Convertir des degràƒÆ’à‚©s en radians
  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// VàƒÆ’à‚©rifier si une position est valide
  bool isValidPosition(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    if (lat < -90 || lat > 90) return false;
    if (lon < -180 || lon > 180) return false;
    return true;
  }

  /// Obtenir une estimation de la pràƒÆ’à‚©cision de la position actuelle
  double? getCurrentAccuracy() {
    return _currentPosition?.accuracy;
  }

  /// Stream de positions pour suivre les changements en temps ràƒÆ’à‚©el
  /// Utile pour une carte en temps ràƒÆ’à‚©el
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 100,
  }) {
    final settings = AndroidSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
