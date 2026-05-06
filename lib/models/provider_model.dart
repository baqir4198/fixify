import 'dart:convert';

class ProviderModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String profession;
  double rating;
  final double pricePerHour;
  String imageUrl; // Profile Picture
  final String cnicUrl;   // Verification Image
  final String about;

  ProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.profession,
    required this.rating,
    required this.pricePerHour,
    required this.imageUrl,
    required this.cnicUrl,
    required this.about,
  });

  // --- FIREBASE SE DATA LENE KE LIYE ---
  factory ProviderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ProviderModel(
      // Agar Firestore ki auto-generated ID pass ho toh wo use karein, warna map se
      id: docId ?? (map['id']?.toString() ?? ''),
      name: map['name']?.toString() ?? 'Unknown User',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      profession: map['profession']?.toString() ?? 'Customer', // Default role

      // Safety for double values
      rating: _toDouble(map['rating']),
      pricePerHour: _toDouble(map['pricePerHour']),

      imageUrl: map['imageUrl']?.toString() ?? 'https://via.placeholder.com/150',
      cnicUrl: map['cnicUrl']?.toString() ?? '',
      about: map['about']?.toString() ?? 'No description provided.',
    );
  }

  // --- FIREBASE MEIN SAVE KARNE KE LIYE ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profession': profession,
      'rating': rating,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
      'cnicUrl': cnicUrl,
      'about': about,
      'updatedAt': DateTime.now().toIso8601String(), // Update time track karne ke liye
    };
  }

  // Helper function taake double conversion mein error na aaye
  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  // JSON conversion (Storage ke liye useful hai)
  String toJson() => json.encode(toMap());
  factory ProviderModel.fromJson(String source) => ProviderModel.fromMap(json.decode(source));
}