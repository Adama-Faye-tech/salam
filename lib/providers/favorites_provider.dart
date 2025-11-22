import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class FavoritesProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;
  final Set<String> _favoriteEquipmentIds = {};
  final Set<String> _favoriteServiceIds = {};
  bool _isLoading = false;

  Set<String> get favoriteEquipmentIds => _favoriteEquipmentIds;
  Set<String> get favoriteServiceIds => _favoriteServiceIds;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        _favoriteEquipmentIds.clear();
        _favoriteServiceIds.clear();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Charger les favoris depuis Supabase
      final response = await _supabase.favorites
          .select('equipment_id')
          .eq('user_id', user.id);

      _favoriteEquipmentIds.clear();
      _favoriteServiceIds.clear();

      for (final item in response) {
        final equipmentId = item['equipment_id'] as String?;
        if (equipmentId != null) {
          _favoriteEquipmentIds.add(equipmentId);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des favoris: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleEquipmentFavorite(String equipmentId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        debugPrint('Utilisateur non connecté');
        return;
      }

      if (_favoriteEquipmentIds.contains(equipmentId)) {
        // Retirer des favoris
        await _supabase.favorites
            .delete()
            .eq('user_id', user.id)
            .eq('equipment_id', equipmentId);
        _favoriteEquipmentIds.remove(equipmentId);
      } else {
        // Ajouter aux favoris
        await _supabase.favorites.insert({
          'user_id': user.id,
          'equipment_id': equipmentId,
        });
        _favoriteEquipmentIds.add(equipmentId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la modification du favori: $e');
    }
  }

  Future<void> toggleServiceFavorite(String serviceId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        debugPrint('Utilisateur non connecté');
        return;
      }

      if (_favoriteServiceIds.contains(serviceId)) {
        // Retirer des favoris
        await _supabase.favorites
            .delete()
            .eq('user_id', user.id)
            .eq('equipment_id', serviceId);
        _favoriteServiceIds.remove(serviceId);
      } else {
        // Ajouter aux favoris
        await _supabase.favorites.insert({
          'user_id': user.id,
          'equipment_id': serviceId,
        });
        _favoriteServiceIds.add(serviceId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la modification du favori: $e');
    }
  }

  bool isEquipmentFavorite(String equipmentId) {
    return _favoriteEquipmentIds.contains(equipmentId);
  }

  bool isServiceFavorite(String serviceId) {
    return _favoriteServiceIds.contains(serviceId);
  }

  int get totalFavorites =>
      _favoriteEquipmentIds.length + _favoriteServiceIds.length;

  Future<void> clearAllFavorites() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        debugPrint('Utilisateur non connecté');
        return;
      }

      // Supprimer tous les favoris de l'utilisateur
      await _supabase.favorites.delete().eq('user_id', user.id);

      _favoriteEquipmentIds.clear();
      _favoriteServiceIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression des favoris: $e');
    }
  }
}
