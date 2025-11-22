class Review {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String itemId; // ID de l'équipement ou du service
  final String providerId;
  final double rating;
  final String comment;
  final List<String> photos;
  final List<String> videos;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.itemId,
    required this.providerId,
    required this.rating,
    required this.comment,
    required this.photos,
    required this.videos,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhoto: json['userPhoto'],
      itemId: json['itemId'] ?? '',
      providerId: json['providerId'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'itemId': itemId,
      'providerId': providerId,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'videos': videos,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}


