import 'dart:convert';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _bookingKey = 'user_bookings';
  static const String _providerKey = 'custom_providers';

  // ================= PROVIDER LOGIC =================

  static Future<void> saveProvider(ProviderModel provider) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> existingProviders = prefs.getStringList(_providerKey) ?? [];
    existingProviders.add(jsonEncode(provider.toMap()));
    await prefs.setStringList(_providerKey, existingProviders);
  }

  static Future<List<ProviderModel>> getSavedProviders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> providerRaw = prefs.getStringList(_providerKey) ?? [];
    return providerRaw.map((p) => ProviderModel.fromMap(jsonDecode(p))).toList();
  }

  // ================= BOOKING LOGIC =================

  static Future<void> saveBooking(BookingModel booking) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookings = prefs.getStringList(_bookingKey) ?? [];
    bookings.add(jsonEncode(booking.toMap()));
    await prefs.setStringList(_bookingKey, bookings);
  }

  static Future<List<BookingModel>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookingsRaw = prefs.getStringList(_bookingKey) ?? [];

    return bookingsRaw.map((item) {
      return BookingModel.fromMap(jsonDecode(item));
    }).toList();
  }

  // NEW: Status Update karne ka function
  static Future<void> updateBookingStatus(String id, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookingsRaw = prefs.getStringList(_bookingKey) ?? [];

    // Saari bookings ko pehle list mein convert karein
    List<BookingModel> bookings = bookingsRaw.map((item) {
      return BookingModel.fromMap(jsonDecode(item));
    }).toList();

    // Match hone wali ID ka status change karein
    int index = bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      bookings[index].status = newStatus;

      // Update hone ke baad puri list ko wapis String list banayein
      List<String> updatedRaw = bookings.map((b) => jsonEncode(b.toMap())).toList();
      await prefs.setStringList(_bookingKey, updatedRaw);
    }
  }

  static Future<void> deleteBooking(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookingsRaw = prefs.getStringList(_bookingKey) ?? [];

    bookingsRaw.removeWhere((item) {
      Map<String, dynamic> data = jsonDecode(item);
      return data['id'].toString() == id;
    });

    await prefs.setStringList(_bookingKey, bookingsRaw);
  }

  static Future<void> updateProviderRating(String providerId, double newRating) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> providerRaw = prefs.getStringList(_providerKey) ?? [];

    // Providers ko list mein convert karein
    List<ProviderModel> providers = providerRaw.map((p) => ProviderModel.fromMap(jsonDecode(p))).toList();

    // Specific provider dhoondo
    int index = providers.indexWhere((p) => p.id == providerId);
    if (index != -1) {
      // Purani rating aur nayi rating ka average bhi nikal sakte hain,
      // lekin filhal hum direct update karte hain simple rakhne ke liye
      providers[index].rating = newRating;

      // Wapis save karein
      List<String> updatedRaw = providers.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_providerKey, updatedRaw);
    }
  }
}