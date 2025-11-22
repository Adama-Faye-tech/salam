class Service {
  final String id;
  final String name;
  final String description;
  final ServiceCategory category;
  final String providerId;
  final String providerName;
  final String? providerPhoto;
  final double? providerRating;
  final double pricePerHour;
  final double pricePerDay;
  final double? pricePerHectare;
  final List<String> photos;
  final List<String> videos;
  final String location;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final String interventionZone;
  final bool isAvailable;
  final List<String>? equipmentUsed; // IDs des équipements utilisés
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.providerId,
    required this.providerName,
    this.providerPhoto,
    this.providerRating,
    required this.pricePerHour,
    required this.pricePerDay,
    this.pricePerHectare,
    required this.photos,
    required this.videos,
    required this.location,
    this.latitude,
    this.longitude,
    this.distance,
    required this.interventionZone,
    required this.isAvailable,
    this.equipmentUsed,
    this.additionalInfo,
    required this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: ServiceCategory.values.firstWhere(
        (e) => e.toString() == 'ServiceCategory.${json['category']}',
        orElse: () => ServiceCategory.autre,
      ),
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      providerPhoto: json['providerPhoto'],
      providerRating: json['providerRating']?.toDouble(),
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      pricePerHectare: json['pricePerHectare']?.toDouble(),
      photos: List<String>.from(json['photos'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      distance: json['distance']?.toDouble(),
      interventionZone: json['interventionZone'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      equipmentUsed: json['equipmentUsed'] != null 
          ? List<String>.from(json['equipmentUsed']) 
          : null,
      additionalInfo: json['additionalInfo'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhoto': providerPhoto,
      'providerRating': providerRating,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'pricePerHectare': pricePerHectare,
      'photos': photos,
      'videos': videos,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'interventionZone': interventionZone,
      'isAvailable': isAvailable,
      'equipmentUsed': equipmentUsed,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

enum ServiceCategory {
  labour,          // Labour
  semis,           // Semis/Semoir
  moisson,         // Moisson
  transport,       // Transport de récolte
  irrigation,      // Irrigation
  pulverisation,   // Pulvérisation
  fertilisation,   // Fertilisation
  autre,           // Autre
}


