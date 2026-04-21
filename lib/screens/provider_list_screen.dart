import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/provider_detail_screen.dart';
import 'package:handyman_app/services/storage_service.dart';

class ProviderListScreen extends StatefulWidget {
  final String categoryName;
  const ProviderListScreen({super.key, required this.categoryName});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  List<ProviderModel> allProviders = [];
  bool isLoading = true;
  @override
  void initState(){
    super.initState();
    _loadAllProviders();
  }
  Future<void> _loadAllProviders()async{
    final List<ProviderModel> dummyProviders=[
      ProviderModel(id:'1',name: 'Ali Ahmad', profession: 'Carpentry', rating: 4.8, pricePerHour: 25.0, imageUrl: "https://i.pravatar.cc/150?u=1"),
      ProviderModel(id:'2',name: 'Sara Khan', profession: 'Painting', rating: 4.9, pricePerHour: 30.0, imageUrl: "https://i.pravatar.cc/150?u=2"),
      ProviderModel(id:'3',name: "Aslam Bhai", profession: "Plumbing", rating: 4.8, pricePerHour: 500, imageUrl: "..."),
      ProviderModel(id:'4',name: "Sajid Electrician", profession: "Electrical", rating: 4.5, pricePerHour: 800, imageUrl: "..."),
      ProviderModel(id:'5',name: "Irfan Plumber", profession: "Plumbing", rating: 4.2, pricePerHour: 450, imageUrl: "..."),
      ProviderModel(id:'6',name: "Irfan Munna", profession: "AC Repair", rating: 4.0, pricePerHour: 450, imageUrl: "..."),
    ];

    final savedProviders = await StorageService.getSavedProviders();

    setState(() {
      allProviders = [...dummyProviders,...savedProviders];
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final filteredProviders = allProviders.where((p)=> p.profession == widget.categoryName).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.categoryName} Services"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ?const Center(child: CircularProgressIndicator())
          :filteredProviders.isEmpty
          ?Center(child: Text("No ${widget.categoryName} available right now"),)
          :ListView.builder(
          itemCount: filteredProviders.length,
          itemBuilder: (context, index){
            final person = filteredProviders[index];
            return GestureDetector(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context)=> ProviderDetailScreen(provider: person)),
                );
                },
              child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(person.imageUrl),),
                title: Text(person.name,style: const TextStyle(fontWeight: FontWeight.bold),),
                subtitle: Text("Rating: ⭐ ${person.rating}"),
                trailing: Text("\$${person.pricePerHour}/hr", style: const TextStyle(color: Colors.green,fontWeight: FontWeight.bold),),
              ),
            ),
          );
        }
      ),
    );
  }
}
