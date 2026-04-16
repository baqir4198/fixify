import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/service_model.dart';

class CategoryCard extends StatelessWidget{
  final ServiceModel service;
  final VoidCallback onTap;
  const CategoryCard({
    super.key,
    required this.service,
    required this.onTap,
});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:service.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: service.color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: service.color,
              radius: 30,
              child: Icon(service.icon,color: Colors.white,size: 30,),
            ),
            const SizedBox(height: 10,),
            Text(
              service.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87
              ),
            )
          ],
        ),
      )
    );
  }
}