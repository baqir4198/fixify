import 'package:handyman_app/models/provider_model.dart';

class BookingModel {
  final String id;
  final ProviderModel provider;
  final DateTime date;
  final String time;
  final String status;

  BookingModel({
    required this.id,
    required this.provider,
    required this.date,
    required this.time,
    this.status = 'Pending',
  });
}