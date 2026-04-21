class ProviderModel {
  final String id;
  final String name;
  final String profession;
  final double rating;
  final double pricePerHour;
  final String imageUrl;
  ProviderModel({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.pricePerHour,
    required this.imageUrl
});
  factory ProviderModel.fromMap(Map<String,dynamic>map){
    return ProviderModel(
        id: map['id'],
        name: map['name'],
        profession: map['profession'],
        rating: map['rating'].toDouble(),
        pricePerHour: map['pricePerHour'].toDouble(),
        imageUrl: map['imageUrl'],
    );
  }
  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'name': name,
      'profession': profession,
      'rating': rating,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
    };
  }
}