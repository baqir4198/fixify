import 'dart:convert';

class ProviderModel {
  final String id;
  final String name;
  final String email;
  final String profession;
  double averageRating;
  final int totalReviews;
  final double pricePerHour;
  String imageUrl;
  final String cnicUrl;
  final String bio;

  final double? latitude;
  final double? longitude;

  ProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profession,
    required this.averageRating,
    required this.totalReviews,
    required this.pricePerHour,
    required this.imageUrl,
    required this.cnicUrl,
    required this.bio,
    this.latitude,
    this.longitude,
  });

  factory ProviderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ProviderModel(
      id: docId ?? (map['id']?.toString() ?? ''),
      name: map['name']?.toString() ?? 'Unknown User',
      email: map['email']?.toString() ?? '',
      profession: map['profession']?.toString() ?? 'Technician',
      averageRating: _toDouble(map['average_rating'] ?? map['rating']),
      totalReviews: map['total_reviews'] is int ? map['total_reviews'] : (int.tryParse(map['total_reviews']?.toString() ?? '0') ?? 0),
      pricePerHour: _toDouble(map['price_per_hour'] ?? map['pricePerHour']),
      imageUrl: map['image_url']?.toString() ?? map['imageUrl']?.toString() ?? 'https://via.placeholder.com/150',
      cnicUrl: map['cnic_url']?.toString() ?? '',
      bio: map['bio']?.toString() ?? (map['about']?.toString() ?? 'No description provided.'),

      latitude: map['latitude'] != null ? _toDouble(map['latitude']) : null,
      longitude: map['longitude'] != null ? _toDouble(map['longitude']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profession': profession,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'price_per_hour': pricePerHour,
      'image_url': imageUrl,
      'cnic_url': cnicUrl,
      'bio': bio,

      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  ProviderModel copyWith({
    String? name,
    String? imageUrl,
    String? bio,
    double? pricePerHour,
    String? profession,
    double? averageRating,
    int? totalReviews,
    double? latitude,
    double? longitude,
  }) {
    return ProviderModel(
      id: id,
      name: name ?? this.name,
      email: email,
      profession: profession ?? this.profession,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      imageUrl: imageUrl ?? this.imageUrl,
      cnicUrl: cnicUrl,
      bio: bio ?? this.bio,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String toJson() => json.encode(toMap());
  factory ProviderModel.fromJson(String source) => ProviderModel.fromMap(json.decode(source));
}