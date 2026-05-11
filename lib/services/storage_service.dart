import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../models/provider_model.dart';
import '../models/message_model.dart';

class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ================= PROVIDER LOGIC =================
  static Future<void> saveProvider(ProviderModel provider) async {
    try {
      await _supabase.from('users').upsert(provider.toMap());
    } catch (e) {
      print("Error saving provider: $e");
      rethrow;
    }
  }

  static Stream<List<ProviderModel>> getProvidersStream() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .neq('profession', 'Customer')
        .map((data) => data.map((map) => ProviderModel.fromMap(map)).toList());
  }

  // ================= BOOKING LOGIC =================
  static Future<void> saveBooking(BookingModel booking) async {
    try {
      // 1. Insert and get back the new row with UUID
      final response = await _supabase
          .from('bookings')
          .insert(booking.toMap())
          .select()
          .single();

      final savedBooking = BookingModel.fromMap(response);

      // 2. Auto welcome message
      await sendAutoWelcomeMessage(savedBooking);
    } catch (e) {
      print("SAVE BOOKING ERROR: $e");
      rethrow;
    }
  }

  static Stream<List<BookingModel>> getBookingsStream(String userId, bool isProvider) {
    final column = isProvider ? 'provider_id' : 'customer_id';

    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq(column, userId)
        .order('booking_date', ascending: false)
        .map((data) => data.map((map) => BookingModel.fromMap(map)).toList());
  }

  static Future<void> updateBookingStatus(String id, String newStatus) async {
    try {
      await _supabase.from('bookings').update({'status': newStatus}).eq('id', id);
    } catch (e) {
      print("Update Status Error: $e");
      rethrow;
    }
  }

  // ================= CHAT LOGIC =================
  static Future<void> sendMessage(MessageModel message) async {
    try {
      final messageData = message.toMap();
      messageData.remove('id'); // ID remove ki taake Supabase UUID banaye
      await _supabase.from('messages').insert(messageData);
    } catch (e) {
      print("Send Message Error: $e");
      rethrow;
    }
  }

  static Stream<List<MessageModel>> getChatStream(String bookingId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('timestamp', ascending: true)
        .map((data) => data.map((map) => MessageModel.fromMap(map)).toList());
  }

  static Future<void> sendAutoWelcomeMessage(BookingModel booking) async {
    try {
      final autoMsg = MessageModel(
        id: '', // Empty rakha
        bookingId: booking.id, // Ab ye sahi UUID hai
        senderId: booking.customerId,
        receiverId: booking.provider.id,
        content: "Hi ${booking.provider.name}, I have booked your service. Let's discuss!",
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      await sendMessage(autoMsg);
    } catch (e) {
      print("Auto Welcome Message Error: $e");
    }
  }
}