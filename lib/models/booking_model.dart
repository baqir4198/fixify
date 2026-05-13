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

  // --- Schema Based Rating Fields ---
  final double? providerRating;
  final double? customerRating;
  final double? customerAverageRating;
  final int? customerTotalReviews;

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
    this.providerRating,
    this.customerRating,
    this.customerAverageRating,
    this.customerTotalReviews,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      // Ensure provider data is handled correctly
      provider: ProviderModel.fromMap(map['provider_data'] ?? {}),
      customerName: map['customer_name'] ?? '',
      customerId: map['customer_id'] ?? '',
      date: DateTime.parse(map['booking_date'] ?? DateTime.now().toIso8601String()),
      time: map['booking_time'] ?? '',
      serviceName: map['service_name'] ?? '',
      price: map['price']?.toString() ?? '0',
      status: (map['status']?.toString() ?? 'Pending').trim(),

      // Mapping from Capture2.PNG (Keeping them nullable for DB consistency)
      providerRating: _toDouble(map['provider_rating']),
      customerRating: _toDouble(map['customer_rating']),
      customerAverageRating: _toDouble(map['customer_average_rating']),
      customerTotalReviews: map['customer_total_reviews'] as int?,
    );
  }

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
      // Important: provider_data agar JSON column hai tabhi bhejein
      'provider_data': provider.toMap(),
      'provider_rating': providerRating,
      'customer_rating': customerRating,
      // Inko toMap mein shamil rakhen taake update queries mein asani ho
    };
  }

  // FIXED: Return null if value is null, don't force 0.0
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    return null;
  }
}