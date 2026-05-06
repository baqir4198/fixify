import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  ServiceModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  // --- FIREBASE INTEGRATION ---

  // Database mein bhejte waqt (Color ko Hex string aur Icon ko codePoint mein badalna)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': icon.codePoint, // Icon ka unique number
      'colorHex': color.value,    // Color ka integer value
    };
  }

  // Database se wapas lete waqt
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      // CodePoint se wapas IconData banana
      icon: IconData(map['iconCode'], fontFamily: 'MaterialIcons'),
      // Integer value se wapas Color banana
      color: Color(map['colorHex'] ?? 0xFF42A5F5),
    );
  }
}