import 'dart:convert';
import 'package:handyman_app/models/provider_model.dart';

class BookingModel {
  final String id;
  final ProviderModel provider;
  final DateTime date;
  final String time;
  String status;

  BookingModel({
    required this.id,
    required this.provider,
    required this.date,
    required this.time,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider': provider.toMap(),
      'date': date.toIso8601String(), // 'data' ko 'date' kar dia hai
      'time': time,
      'status': status,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id']?.toString() ?? '',
      // Provider check: agar provider map null ho to empty map bhej rahay hain
      provider: ProviderModel.fromMap(map['provider'] ?? {}),
      // Date check: agar date missing ho to aaj ki date set ho jaye
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      time: map['time']?.toString() ?? '00:00',
      status: map['status']?.toString() ?? 'Pending',
    );
  }

  factory BookingModel.fromJson(String source) =>
      BookingModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}