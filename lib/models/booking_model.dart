import 'provider_model.dart';

class BookingModel {
  final String id;
  final ProviderModel provider;
  final String customerName;
  final String customerId;
  final DateTime date;
  final String time;
  final String serviceName;
  final String price;
  final String status;

  BookingModel({
    required this.id,
    required this.provider,
    required this.customerName,
    required this.customerId,
    required this.date,
    required this.time,
    required this.serviceName,
    required this.price,
    required this.status,
  });

  // Supabase/JSON se data nikalne ke liye
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      provider: ProviderModel.fromMap(map['provider_data'] ?? {}),
      customerName: map['customer_name'] ?? '',
      customerId: map['customer_id'] ?? '',
      date: DateTime.parse(map['booking_date']),
      time: map['booking_time'] ?? '',
      serviceName: map['service_name'] ?? '',
      price: map['price'] ?? '0',
      status: map['status'] ?? 'Pending',
    );
  }

  // Database mein save karne ke liye
  Map<String, dynamic> toMap() {
    return {
      'customer_name': customerName,
      'customer_id': customerId,
      'booking_date': date.toIso8601String(),
      'booking_time': time,
      'service_name': serviceName,
      'price': price,
      'status': status,
      'provider_id': provider.id,
      // Provider ki basic details save karna zaroori hota hai history ke liye
      'provider_data': provider.toMap(),
    };
  }
}