class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? address;
  final String? location;
  final UserType userType;
  final String? description;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.address,
    this.location,
    required this.userType,
    this.description,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      // Accept multiple photo key variants
      photoUrl: json['photoUrl'] ?? json['photo_url'] ?? json['photo'],
      address: json['address'],
      location: json['location'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${json['userType']}',
        orElse: () => UserType.farmer,
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      // Export both camelCase and snake_case for compatibility
      'photoUrl': photoUrl,
      'photo_url': photoUrl,
      'address': address,
      'location': location,
      'userType': userType.toString().split('.').last,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? address,
    String? location,
    UserType? userType,
    String? description,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      location: location ?? this.location,
      userType: userType ?? this.userType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum UserType {
  farmer,      // Agriculteur
  provider,    // Prestataire
  both,        // Les deux
}

