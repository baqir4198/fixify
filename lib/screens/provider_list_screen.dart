import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';

class ProviderListScreen extends StatelessWidget {
  final String categoryName;
  const ProviderListScreen({super.key, required this.categoryName});


  @override
  Widget build(BuildContext context) {
    List<ProviderModel> providers=[
      ProviderModel(name: 'Ali Ahmad', profession: categoryName, rating: 4.8, pricePerHour: 25.0, imageUrl: "https://i.pravatar.cc/150?u=1"),
      ProviderModel(name: 'Sara Khan', profession: categoryName, rating: 4.9, pricePerHour: 30.0, imageUrl: "https://i.pravatar.cc/150?u=2"),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text("$categoryName Experts"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: providers.length,
        itemBuilder: (context, index){
          final person = providers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(person.imageUrl),),
              title: Text(person.name,style: const TextStyle(fontWeight: FontWeight.bold),),
              subtitle: Text("Rating: ⭐ ${person.rating}"),
              trailing: Text("\$${person.pricePerHour}/hr", style: const TextStyle(color: Colors.green,fontWeight: FontWeight.bold),),
            ),
          );
        }
      ),
    );
  }
}
