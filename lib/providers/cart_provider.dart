import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  // ApiService retiré - codes promo gérés en local pour déploiement
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _promoCode;
  double _discount = 0;
  String? _promoType;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get promoCode => _promoCode;
  double get discount => _discount;

  int get itemCount => _items.length;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get total {
    return subtotal - _discount;
  }

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');

      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items = decoded.map((item) => CartItem.fromJson(item)).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(CartItem item) async {
    _items.add(item);
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    await _saveCart();
    notifyListeners();
  }

  Future<void> updateItem(CartItem updatedItem) async {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> updateDates(
    String itemId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        startDate: startDate,
        endDate: endDate,
      );
      await _saveCart();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> applyPromoCode(String code) async {
    if (code.trim().isEmpty) {
      return {'success': false, 'message': 'Code promo vide'};
    }

    try {
      // Codes promo en dur pour fonctionnement sans backend local
      // TODO: Migrer vers Supabase table promo_codes ou Supabase Functions
      final Map<String, Map<String, dynamic>> demoCodes = {
        'SALAM10': {
          'code': 'SALAM10',
          'discount': 0.10,
          'type': 'percentage',
          'description': 'Réduction de 10%',
        },
        'SALAM20': {
          'code': 'SALAM20',
          'discount': 0.20,
          'type': 'percentage',
          'description': 'Réduction de 20%',
        },
        'BIENVENUE': {
          'code': 'BIENVENUE',
          'discount': 5000.0,
          'type': 'fixed',
          'description': 'Réduction de 5000 FCFA',
        },
      };

      final upperCode = code.trim().toUpperCase();

      if (demoCodes.containsKey(upperCode)) {
        final promoData = demoCodes[upperCode]!;
        _promoCode = promoData['code'];
        _promoType = promoData['type'];

        // Calculer la réduction selon le type
        if (_promoType == 'percentage') {
          _discount = subtotal * promoData['discount'];
        } else if (_promoType == 'fixed') {
          _discount = promoData['discount'].toDouble();
        }

        notifyListeners();
        return {'success': true, 'message': promoData['description']};
      } else {
        return {'success': false, 'message': 'Code promo invalide ou expiré'};
      }
    } catch (e) {
      debugPrint('Erreur application code promo: $e');
      return {'success': false, 'message': 'Erreur de vérification'};
    }
  }

  void removePromoCode() {
    _promoCode = null;
    _discount = 0;
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    _promoCode = null;
    _discount = 0;
    await _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString('cart', cartJson);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  bool isInCart(String itemId) {
    return _items.any((item) => item.itemId == itemId);
  }

  CartItem? getCartItem(String itemId) {
    try {
      return _items.firstWhere((item) => item.itemId == itemId);
    } catch (e) {
      return null;
    }
  }
}
