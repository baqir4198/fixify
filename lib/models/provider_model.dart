class ProviderModel {
  final String id;
  final String name;
  final String email;    // Naya field login ke liye
  final String password; // Naya field security ke liye
  final String profession;
  double rating;
  final double pricePerHour;
  final String imageUrl;
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
    required this.about,
  });

  factory ProviderModel.fromMap(Map<String, dynamic> map) {
    return ProviderModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown User',
      email: map['email']?.toString() ?? '',       // Email map se uthayi
      password: map['password']?.toString() ?? '', // Password map se uthaya
      profession: map['profession']?.toString() ?? 'General Service',
      rating: (map['rating'] ?? 0.0).toDouble(),
      pricePerHour: (map['pricePerHour'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl']?.toString() ?? 'https://i.pravatar.cc/150',
      about: map['about']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,       // Email save karne ke liye
      'password': password, // Password save karne ke liye
      'profession': profession,
      'rating': rating,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
      'about': about,
    };
  }
}