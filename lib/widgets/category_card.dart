import 'package:flutter/material.dart';
import '../models/service_model.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Material( // Material add kiya taake InkWell ka splash nazar aaye
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: service.color.withOpacity(0.1),
        highlightColor: service.color.withOpacity(0.05),
        child: AnimatedContainer( // Click feel behtar karne ke liye
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03), // Zyada natural shadow
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: service.color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15), // Circle ki jagah Rounded Square
                ),
                child: Icon(
                  service.icon,
                  size: 30,
                  color: service.color,
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                service.name,
                style: GoogleFonts.poppins( // Professional Font
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              // Status/Subtitle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  "Available", // "Book Now" ki jagah zyada trust-building word
                  style: TextStyle(
                    fontSize: 10,
                    color: service.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}