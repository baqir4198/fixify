class ProviderModel {
  final String id;
  final String name;
  final String profession;
  double rating;
  final double pricePerHour;
  final String imageUrl;
  final String about;

  ProviderModel({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.pricePerHour,
    required this.imageUrl, required this.about,
  });

  factory ProviderModel.fromMap(Map<String, dynamic> map) {
    return ProviderModel(
      // ?? ka matlab hai agar left side null ho toh right side wali value use karo
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown User',
      profession: map['profession']?.toString() ?? 'General Service',

      // Number conversion ko safe banaya hai taake int/double ka masla na ho
      rating: (map['rating'] ?? 0.0).toDouble(),
      pricePerHour: (map['pricePerHour'] ?? 0.0).toDouble(),

      imageUrl: map['imageUrl']?.toString() ?? 'https://i.pravatar.cc/150', about: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profession': profession,
      'rating': rating,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
    };
  }
}