import 'equipment_model.dart';
import 'service_model.dart';

class CartItem {
  final String id;
  final ItemType type;
  final String itemId;
  final String name;
  final String? photoUrl;
  final double price;
  final PriceUnit priceUnit;
  final DateTime startDate;
  final DateTime endDate;
  final int quantity;
  final String? notes;

  CartItem({
    required this.id,
    required this.type,
    required this.itemId,
    required this.name,
    this.photoUrl,
    required this.price,
    required this.priceUnit,
    required this.startDate,
    required this.endDate,
    this.quantity = 1,
    this.notes,
  });

  double get totalPrice {
    if (priceUnit == PriceUnit.perHour) {
      final hours = endDate.difference(startDate).inHours;
      return price * hours * quantity;
    } else if (priceUnit == PriceUnit.perDay) {
      final days = endDate.difference(startDate).inDays;
      return price * (days > 0 ? days : 1) * quantity;
    } else {
      return price * quantity;
    }
  }

  factory CartItem.fromEquipment(
    Equipment equipment, 
    DateTime startDate, 
    DateTime endDate,
    PriceUnit priceUnit,
  ) {
    return CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ItemType.equipment,
      itemId: equipment.id,
      name: equipment.name,
      photoUrl: equipment.photos.isNotEmpty ? equipment.photos.first : null,
      price: priceUnit == PriceUnit.perHour ? equipment.pricePerHour : equipment.pricePerDay,
      priceUnit: priceUnit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  factory CartItem.fromService(
    Service service, 
    DateTime startDate, 
    DateTime endDate,
    PriceUnit priceUnit,
  ) {
    return CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ItemType.service,
      itemId: service.id,
      name: service.name,
      photoUrl: service.photos.isNotEmpty ? service.photos.first : null,
      price: priceUnit == PriceUnit.perHour ? service.pricePerHour : service.pricePerDay,
      priceUnit: priceUnit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      type: ItemType.values.firstWhere(
        (e) => e.toString() == 'ItemType.${json['type']}',
        orElse: () => ItemType.equipment,
      ),
      itemId: json['itemId'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      price: (json['price'] ?? 0).toDouble(),
      priceUnit: PriceUnit.values.firstWhere(
        (e) => e.toString() == 'PriceUnit.${json['priceUnit']}',
        orElse: () => PriceUnit.perDay,
      ),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      quantity: json['quantity'] ?? 1,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'itemId': itemId,
      'name': name,
      'photoUrl': photoUrl,
      'price': price,
      'priceUnit': priceUnit.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'quantity': quantity,
      'notes': notes,
    };
  }

  CartItem copyWith({
    String? id,
    ItemType? type,
    String? itemId,
    String? name,
    String? photoUrl,
    double? price,
    PriceUnit? priceUnit,
    DateTime? startDate,
    DateTime? endDate,
    int? quantity,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

enum ItemType {
  equipment,
  service,
}

enum PriceUnit {
  perHour,
  perDay,
  perHectare,
}

