import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class ProviderOrdersScreen extends StatefulWidget {
  const ProviderOrdersScreen({super.key});

  @override
  State<ProviderOrdersScreen> createState() => _ProviderOrdersScreenState();
}

class _ProviderOrdersScreenState extends State<ProviderOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    
    if (userProvider.currentUser != null) {
      await ordersProvider.loadOrders(userProvider.currentUser!.id.toString());
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(Order order) async {
    try {
      final apiService = ApiService();
      await apiService.updateOrderStatus(
        orderId: int.tryParse(order.id) ?? 0,
        status: 'confirmed',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('à¢Å“€¦ Réservation confirmée'),
          backgroundColor: Colors.green,
        ),
      );

      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _rejectOrder(Order order) async {
    try {
      final apiService = ApiService();
      await apiService.updateOrderStatus(
        orderId: int.tryParse(order.id) ?? 0,
        status: 'cancelled',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation refusée'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _markInProgress(Order order) async {
    try {
      final apiService = ApiService();
      await apiService.updateOrderStatus(
        orderId: int.tryParse(order.id) ?? 0,
        status: 'in_progress',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('à¢Å“€¦ Marqué comme en cours')),
      );

      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _markCompleted(Order order) async {
    try {
      final apiService = ApiService();
      await apiService.updateOrderStatus(
        orderId: int.tryParse(order.id) ?? 0,
        status: 'completed',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('à¢Å“€¦ Prestation terminée !'),
          backgroundColor: Colors.green,
        ),
      );

      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nouvelles'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<OrdersProvider>(
              builder: (context, ordersProvider, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(ordersProvider.pendingOrders, 'pending'),
                    _buildOrdersList([
                      ...ordersProvider.confirmedOrders,
                      ...ordersProvider.inProgressOrders,
                    ], 'active'),
                    _buildOrdersList(ordersProvider.completedOrders, 'completed'),
                    _buildOrdersList(ordersProvider.cancelledOrders, 'cancelled'),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, String tab) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune commande',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, tab);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, String tab) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Nouvelle demande';
        statusIcon = Icons.new_releases;
        break;
      case OrderStatus.confirmed:
        statusColor = Colors.blue;
        statusText = 'Confirmée';
        statusIcon = Icons.check_circle;
        break;
      case OrderStatus.inProgress:
        statusColor = Colors.purple;
        statusText = 'En cours';
        statusIcon = Icons.play_circle;
        break;
      case OrderStatus.completed:
        statusColor = Colors.green;
        statusText = 'Terminée';
        statusIcon = Icons.done_all;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Annulée';
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 20, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(order.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        order.providerName[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Client',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            order.providerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Équipement
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (order.itemPhoto != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            order.itemPhoto!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.agriculture, size: 24),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.itemName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Début',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(order.startDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            timeFormat.format(order.startDate),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: Colors.grey[400]),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Fin',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(order.endDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            timeFormat.format(order.endDate),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Durée et prix
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Durée',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.durationInHours >= 24
                              ? '${(order.durationInHours / 24).ceil()} jour(s)'
                              : '${order.durationInHours}h',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.price.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Notes
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.message, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Actions selon le statut
                const SizedBox(height: 16),
                if (order.status == OrderStatus.pending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectOrder(order),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Refuser'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptOrder(order),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Accepter'),
                        ),
                      ),
                    ],
                  ),
                ] else if (order.status == OrderStatus.confirmed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markInProgress(order),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Démarrer la prestation'),
                    ),
                  ),
                ] else if (order.status == OrderStatus.inProgress) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markCompleted(order),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Marquer comme terminé'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


