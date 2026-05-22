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


  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon_code': icon.codePoint,
      'color_hex': color.value,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',

      icon: IconData(
        map['icon_code'] ?? 58315,
        fontFamily: 'MaterialIcons',
      ),

      color: Color(int.parse(map['color_hex'].toString())),
    );
  }
}