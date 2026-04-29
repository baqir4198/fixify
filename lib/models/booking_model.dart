import 'dart:convert';
import 'package:handyman_app/models/provider_model.dart';

class BookingModel {
  final String id;
  final ProviderModel provider; // Kis ko book kiya
  final String customerName;    // Kis ne book kiya (Name display ke liye)
  final String customerId;      // Customer ki unique ID
  final DateTime date;
  final String time;
  final String serviceName;     // Kaam kya hai (e.g., AC Repair)
  final String price;           // Kitne paise taiy huay
  String status;

  BookingModel({
    required this.id,
    required this.provider,
    required this.customerName,
    required this.customerId,
    required this.date,
    required this.time,
    required this.serviceName,
    required this.price,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider': provider.toMap(),
      'customerName': customerName,
      'customerId': customerId,
      'date': date.toIso8601String(),
      'time': time,
      'serviceName': serviceName,
      'price': price,
      'status': status,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id']?.toString() ?? '',
      provider: ProviderModel.fromMap(map['provider'] ?? {}),
      customerName: map['customerName'] ?? 'Unknown Customer',
      customerId: map['customerId'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      time: map['time']?.toString() ?? '00:00',
      serviceName: map['serviceName'] ?? 'General Service',
      price: map['price']?.toString() ?? '0',
      status: map['status']?.toString() ?? 'Pending',
    );
  }

  factory BookingModel.fromJson(String source) => BookingModel.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}