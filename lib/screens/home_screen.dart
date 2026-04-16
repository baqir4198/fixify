import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:handyman_app/screens/provider_list_screen.dart';
import 'package:handyman_app/widgets/category_card.dart';

import '../models/service_model.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<ServiceModel> categories=[
    ServiceModel(id: '1',name: 'Plumbing',icon: Icons.plumbing,color: Colors.blue),
    ServiceModel(id: '2',name: 'Electrical',icon: Icons.electrical_services,color: Colors.orange),
    ServiceModel(id: '3',name: 'Cleaning',icon: Icons.cleaning_services,color: Colors.green),
    ServiceModel(id: '4',name: 'Painting',icon: Icons.format_paint,color: Colors.purple),
    ServiceModel(id: '5',name: 'Carpentry',icon: Icons.carpenter,color: Colors.brown),
    ServiceModel(id: '6',name: 'AC Repair',icon: Icons.ac_unit,color: Colors.cyan)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('HandyMan Services',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What serivce do\nyou need today?",
              style:TextStyle(fontSize: 28,fontWeight: FontWeight.bold) ,
            ),
            const SizedBox(height: 20,),
            Expanded(
                child:GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.9,
                    ),
                  itemCount: categories.length,
                  itemBuilder: (context, index){
                      return CategoryCard(
                        service: categories[index],
                        onTap:(){
                          Navigator.push(context,
                            MaterialPageRoute(
                                builder:(context)=>ProviderListScreen(categoryName: categories[index].name),
                            )
                          );
                        }
                      );
                  }
                )
            )
          ],
        ),
      ),
    );
  }
}
