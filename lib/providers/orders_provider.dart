import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class OrdersProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Order> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();
  List<Order> get confirmedOrders =>
      _orders.where((o) => o.status == OrderStatus.confirmed).toList();
  List<Order> get inProgressOrders =>
      _orders.where((o) => o.status == OrderStatus.inProgress).toList();
  List<Order> get completedOrders =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();
  List<Order> get cancelledOrders =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();

  /// Charger toutes les commandes de l'utilisateur
  Future<void> loadOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        _error = 'Utilisateur non connecté';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Charger les commandes où l'utilisateur est client
      final ordersData = await _supabase.orders
          .select()
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      _orders = ordersData.map((json) => Order.fromJson(json)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement des commandes: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint(_error);
    }
  }

  /// Charger les commandes où l'utilisateur est prestataire
  Future<void> loadProviderOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        _error = 'Utilisateur non connecté';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Charger les commandes où l'utilisateur est prestataire
      final ordersData = await _supabase.orders
          .select()
          .eq('provider_id', user.id)
          .order('created_at', ascending: false);

      _orders = ordersData.map((json) => Order.fromJson(json)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement des commandes prestataire: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint(_error);
    }
  }

  /// Créer une nouvelle commande
  Future<void> createOrder(Order order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        _error = 'Utilisateur non connecté';
        _isLoading = false;
        notifyListeners();
        throw Exception(_error);
      }

      // Créer la commande dans Supabase
      final result = await _supabase.orders
          .insert({
            'customer_id': user.id,
            'provider_id': order.providerId,
            'equipment_id': order.itemId,
            'start_date': order.startDate.toIso8601String(),
            'end_date': order.endDate.toIso8601String(),
            'total_price': order.price,
            'status': order.status.toString().split('.').last,
            'notes': order.location,
          })
          .select()
          .single();

      _orders.insert(0, Order.fromJson(result));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de création de commande: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint(_error);
      rethrow;
    }
  }

  /// Mettre à jour le statut d'une commande
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        _error = 'Utilisateur non connecté';
        _isLoading = false;
        notifyListeners();
        throw Exception(_error);
      }

      // Mettre à jour le statut dans Supabase
      final result = await _supabase.orders
          .update({'status': status.toString().split('.').last})
          .eq('id', orderId)
          .select()
          .single();

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = Order.fromJson(result);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de mise à jour du statut: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint(_error);
      rethrow;
    }
  }

  /// Annuler une commande
  Future<void> cancelOrder(String orderId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mise à jour du statut via API
      await updateOrderStatus(orderId, OrderStatus.cancelled);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur d\'annulation: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint(_error);
      rethrow;
    }
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (e) {
      return null;
    }
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((o) => o.status == status).toList();
  }
}
