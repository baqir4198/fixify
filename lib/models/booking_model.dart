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

  // --- Rating Fields ---
  final double? customerAverageRating;
  final int? customerTotalReviews;
  final double? providerRatingGiven;

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
    this.customerAverageRating,
    this.customerTotalReviews,
    this.providerRatingGiven,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    // Status ko handle karne ka sab se safe tareeka
    String rawStatus = map['status']?.toString() ?? 'Pending';

    return BookingModel(
      id: map['id'] ?? '',
      // Provider data agar string format mein aaye ya map mein, dono handle ho jayenge
      provider: ProviderModel.fromMap(map['provider_data'] ?? {}),
      customerName: map['customer_name'] ?? '',
      customerId: map['customer_id'] ?? '',
      date: DateTime.parse(map['booking_date'] ?? DateTime.now().toIso8601String()),
      time: map['booking_time'] ?? '',
      serviceName: map['service_name'] ?? '',
      price: map['price']?.toString() ?? '0',
      // Trim zaroori hai taake "Pending " aur "Pending" ka faraq khatam ho jaye
      status: rawStatus.trim(),

      customerAverageRating: _toDouble(map['customer_rating_at_time'] ?? map['customer_average_rating']),
      customerTotalReviews: map['customer_total_reviews'] as int?,
      providerRatingGiven: _toDouble(map['customer_rating']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ID auto-generate hoti hai DB mein isliye yahan se nahi bhej rahe
      'customer_name': customerName,
      'customer_id': customerId,
      'booking_date': date.toIso8601String(),
      'booking_time': time,
      'service_name': serviceName,
      'price': price,
      'status': status, // Status hamesha update ho kar jayega
      'provider_id': provider.id,
      'provider_data': provider.toMap(),
      'customer_average_rating': customerAverageRating,
      'customer_total_reviews': customerTotalReviews,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method taake code mein status check karna asaan ho
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
}