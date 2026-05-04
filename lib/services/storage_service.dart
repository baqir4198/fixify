import 'dart:convert';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_model.dart';

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

  static Future<void> updateProvider(ProviderModel updatedProvider) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> providerRaw = prefs.getStringList(_providerKey) ?? [];
    List<ProviderModel> providers = providerRaw.map((p) => ProviderModel.fromMap(jsonDecode(p))).toList();

    int index = providers.indexWhere((p) => p.id == updatedProvider.id);
    if (index != -1) {
      providers[index] = updatedProvider;
      List<String> updatedRaw = providers.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_providerKey, updatedRaw);
    }
  }

  // ================= BOOKING LOGIC =================

  static Future<void> saveBooking(BookingModel booking) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookings = prefs.getStringList(_bookingKey) ?? [];
    bookings.add(jsonEncode(booking.toMap()));
    await prefs.setStringList(_bookingKey, bookings);
  }

  // --- STREAM LOGIC: For Automatic Refresh ---
  static Stream<List<BookingModel>> getBookingsStream() async* {
    while (true) {
      // Har 2 second baad data fetch karega
      await Future.delayed(const Duration(seconds: 2));
      final bookings = await getBookings();
      yield bookings;
    }
  }

  static Future<List<BookingModel>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookingsRaw = prefs.getStringList(_bookingKey) ?? [];
    return bookingsRaw.map((item) => BookingModel.fromMap(jsonDecode(item))).toList();
  }

  static Future<List<BookingModel>> getBookingsForProvider(String providerId) async {
    final bookings = await getBookings();
    return bookings.where((booking) => booking.provider.id == providerId).toList();
  }

  static Future<List<BookingModel>> getBookingsForCustomer(String customerId) async {
    final bookings = await getBookings();
    return bookings.where((booking) => booking.customerId == customerId).toList();
  }

  static Future<void> updateBookingStatus(String id, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookingsRaw = prefs.getStringList(_bookingKey) ?? [];
    List<BookingModel> bookings = bookingsRaw.map((item) => BookingModel.fromMap(jsonDecode(item))).toList();

    int index = bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      bookings[index].status = newStatus;
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
    List<ProviderModel> providers = providerRaw.map((p) => ProviderModel.fromMap(jsonDecode(p))).toList();

    int index = providers.indexWhere((p) => p.id == providerId);
    if (index != -1) {
      providers[index].rating = newRating;
      List<String> updatedRaw = providers.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_providerKey, updatedRaw);
    }
  }

  // ... purana code wese hi rahega, ye niche add kar dein ...

  static const String _chatKey = 'chat_messages';

// 1. Message Save karne ke liye
  static Future<void> sendMessage(MessageModel message) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatsRaw = prefs.getStringList(_chatKey) ?? [];
    chatsRaw.add(jsonEncode(message.toMap()));
    await prefs.setStringList(_chatKey, chatsRaw);
  }

// 2. Kisi khas Booking ki Chat nikalne ke liye (Stream version)
  static Stream<List<MessageModel>> getChatStream(String bookingId) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1)); // Chat tez refresh honi chahiye
      final prefs = await SharedPreferences.getInstance();
      List<String> chatsRaw = prefs.getStringList(_chatKey) ?? [];

      final messages = chatsRaw
          .map((m) => MessageModel.fromMap(jsonDecode(m)))
          .where((m) => m.bookingId == bookingId)
          .toList();

      // Time ke hisab se sort karna (purane upar, naye niche)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      yield messages;
    }
  }

// 3. AUTOMATIC MESSAGE LOGIC
// Isay tab call karein jab booking "Save" ho rahi ho
  static Future<void> sendAutoWelcomeMessage(BookingModel booking) async {
    final autoMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: booking.id,
      senderId: booking.customerId, // Customer ki taraf se auto jayega
      receiverId: booking.provider.id,
      content: "Hi ${booking.provider.name}, I have booked your service for ${DateFormat('EEE, MMM d').format(booking.date)}. Let's discuss the details!",
      timestamp: DateTime.now(),
    );
    await sendMessage(autoMsg);
  }

// 4. Update Message Status (For Blue Ticks)
  static Future<void> markAsSeen(String bookingId, String currentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatsRaw = prefs.getStringList(_chatKey) ?? [];
    List<MessageModel> allMessages = chatsRaw.map((m) => MessageModel.fromMap(jsonDecode(m))).toList();

    bool changed = false;
    for (var msg in allMessages) {
      if (msg.bookingId == bookingId && msg.receiverId == currentUserId && !msg.isSeen) {
        msg.isSeen = true;
        changed = true;
      }
    }

    if (changed) {
      List<String> updatedRaw = allMessages.map((m) => jsonEncode(m.toMap())).toList();
      await prefs.setStringList(_chatKey, updatedRaw);
    }
  }
}