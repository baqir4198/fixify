import 'package:flutter/material.dart';
import '../models/service_model.dart';

class CategoryCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: service.color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: service.color.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container with soft background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: service.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                service.icon,
                size: 32,
                color: service.color,
              ),
            ),
            const SizedBox(height: 12),
            // Text Label
            Text(
              service.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle (Optional but looks pro)
            Text(
              "Book Now",
              style: TextStyle(
                fontSize: 11,
                color: service.color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}