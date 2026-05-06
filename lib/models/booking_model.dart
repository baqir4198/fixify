import 'dart:convert';
import 'package:handyman_app/models/provider_model.dart';

class BookingModel {
  final String id;
  final ProviderModel provider;
  final String customerName;
  final String customerId;
  final DateTime date;
  final String time;
  final String serviceName;
  final String price;
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

  // Data Firebase bhejte waqt
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider': provider.toMap(),
      'customerName': customerName,
      'customerId': customerId,
      'date': date.toIso8601String(), // Standard format for flexibility
      'time': time,
      'serviceName': serviceName,
      'price': price,
      'status': status,
    };
  }

  // Data Firebase se lete waqt
  factory BookingModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return BookingModel(
      // Agar Firebase ki doc ID alag se pass ho toh wo use karein
      id: docId ?? (map['id']?.toString() ?? ''),
      provider: ProviderModel.fromMap(map['provider'] ?? {}),
      customerName: map['customerName'] ?? 'Unknown Customer',
      customerId: map['customerId'] ?? '',
      // Parsing logic for ISO string or safety fallback
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      time: map['time']?.toString() ?? '00:00',
      serviceName: map['serviceName'] ?? 'General Service',
      price: map['price']?.toString() ?? '0',
      status: map['status']?.toString() ?? 'Pending',
    );
  }

  factory BookingModel.fromJson(String source) => BookingModel.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());

  // CopyWith Method (Status update karne ke liye best hai bina poora object dobara banaye)
  BookingModel copyWith({String? status}) {
    return BookingModel(
      id: id,
      provider: provider,
      customerName: customerName,
      customerId: customerId,
      date: date,
      time: time,
      serviceName: serviceName,
      price: price,
      status: status ?? this.status,
    );
  }
}