class Equipment {
  final String id;
  final String name;
  final String description;
  final EquipmentType type;
  final String category; // Labour, Semoir, Irrigation, etc.
  final double pricePerHour;
  final double pricePerDay;
  final String year;
  final String? model;
  final String? brand;
  final List<String> photos;
  final List<String> videos;
  final String providerId;
  final String providerName;
  final String? providerPhoto;
  final double? providerRating;
  final String location;
  final double? latitude;
  final double? longitude;
  final double? distance; // Distance from user in km
  final bool isAvailable;
  final Map<String, dynamic>? technicalSpecs;
  final String interventionZone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.year,
    this.model,
    this.brand,
    required this.photos,
    required this.videos,
    required this.providerId,
    required this.providerName,
    this.providerPhoto,
    this.providerRating,
    required this.location,
    this.latitude,
    this.longitude,
    this.distance,
    required this.isAvailable,
    this.technicalSpecs,
    required this.interventionZone,
    required this.createdAt,
    this.updatedAt,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: EquipmentType.values.firstWhere(
        (e) => e.toString() == 'EquipmentType.${json['type']}',
        orElse: () => EquipmentType.autre,
      ),
      category: json['category'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      year: json['year'] ?? '',
      model: json['model'],
      brand: json['brand'],
      photos: List<String>.from(json['photos'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      providerPhoto: json['providerPhoto'],
      providerRating: json['providerRating']?.toDouble(),
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      distance: json['distance']?.toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      technicalSpecs: json['technicalSpecs'],
      interventionZone: json['interventionZone'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'year': year,
      'model': model,
      'brand': brand,
      'photos': photos,
      'videos': videos,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhoto': providerPhoto,
      'providerRating': providerRating,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'isAvailable': isAvailable,
      'technicalSpecs': technicalSpecs,
      'interventionZone': interventionZone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    EquipmentType? type,
    String? category,
    double? pricePerHour,
    double? pricePerDay,
    String? year,
    String? model,
    String? brand,
    List<String>? photos,
    List<String>? videos,
    String? providerId,
    String? providerName,
    String? providerPhoto,
    double? providerRating,
    String? location,
    double? latitude,
    double? longitude,
    double? distance,
    bool? isAvailable,
    Map<String, dynamic>? technicalSpecs,
    String? interventionZone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      year: year ?? this.year,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhoto: providerPhoto ?? this.providerPhoto,
      providerRating: providerRating ?? this.providerRating,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      isAvailable: isAvailable ?? this.isAvailable,
      technicalSpecs: technicalSpecs ?? this.technicalSpecs,
      interventionZone: interventionZone ?? this.interventionZone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum EquipmentType {
  tracteur,
  charrue,
  semoir,
  moissonneuse,
  motoculteur,
  remorque,
  irrigation,
  pulverisateur,
  autre,
}

