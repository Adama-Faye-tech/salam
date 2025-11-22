class Order {
  final String id;
  final String userId;
  final String providerId;
  final String providerName;
  final String? providerPhoto;
  final OrderType type; // Équipement ou Service
  final String itemId; // ID de l'équipement ou du service
  final String itemName;
  final String? itemPhoto;
  final OrderStatus status;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final int durationInHours;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? cancelReason;
  final DateTime? cancelledAt;

  Order({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.providerName,
    this.providerPhoto,
    required this.type,
    required this.itemId,
    required this.itemName,
    this.itemPhoto,
    required this.status,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.durationInHours,
    required this.location,
    this.latitude,
    this.longitude,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.cancelReason,
    this.cancelledAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      providerPhoto: json['providerPhoto'],
      type: OrderType.values.firstWhere(
        (e) => e.toString() == 'OrderType.${json['type']}',
        orElse: () => OrderType.equipment,
      ),
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      itemPhoto: json['itemPhoto'],
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => OrderStatus.pending,
      ),
      price: (json['price'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      durationInHours: json['durationInHours'] ?? 0,
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      cancelReason: json['cancelReason'],
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhoto': providerPhoto,
      'type': type.toString().split('.').last,
      'itemId': itemId,
      'itemName': itemName,
      'itemPhoto': itemPhoto,
      'status': status.toString().split('.').last,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationInHours': durationInHours,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }
}

enum OrderType {
  equipment,  // Location d'équipement
  service,    // Prestation de service
}

enum OrderStatus {
  pending,      // En attente de validation
  confirmed,    // Confirmé
  inProgress,   // En cours
  completed,    // Terminé
  cancelled,    // Annulé
}


