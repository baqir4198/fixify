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

  // --- SUPABASE INTEGRATION ---

  // Database mein insert/update karne ke liye
  Map<String, dynamic> toMap() {
    return {
      // Supabase mein IDs aksar 'id' hi hoti hain (UUID ya BigInt)
      'name': name,
      'icon_code': icon.codePoint, // Snake case use karein: icon_code
      'color_hex': color.value,    // Snake case use karein: color_hex
    };
  }

  // Database se data fetch karne ke liye
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      // Supabase se ID hamesha check karein (kabhi int hoti hai kabhi UUID string)
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',

      // Icon handling
      icon: IconData(
        map['icon_code'] ?? 58315, // Default icon code agar null ho
        fontFamily: 'MaterialIcons',
      ),

      // Color handling
      // Supabase se integer value kabhi kabhi double ya string mein cast ho jati hai
      // isliye .toInt() safety ke liye behtar hai
      color: Color(int.parse(map['color_hex'].toString())),
    );
  }
}