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
      final response = await _supabase
          .from('bookings')
          .insert(booking.toMap())
          .select()
          .single();

      final savedBooking = BookingModel.fromMap(response);
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
      await _supabase
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', id);

      print("Database Status Successfully Updated to: $newStatus");
    } catch (e) {
      print("Update Status Error: $e");
      rethrow;
    }
  }

  // ================= RATING & COMPLETION (FIXED) =================
  static Future<void> completeAndRateTask({
    required BookingModel booking,
    required double rating,
  }) async {
    try {
      print("=== Calling update_booking_rating function ===");
      print("Booking ID: ${booking.id}");
      print("Rating: $rating");

      final result = await _supabase.rpc('update_booking_rating', params: {
        'p_booking_id': booking.id,
        'p_rating': rating,
      });

      print("Function result: $result");

      if (result != null) {
        final updatedRating = result['provider_rating'];
        print("Updated provider_rating: $updatedRating");

        if (updatedRating == rating) {
          print("✅ Rating saved successfully!");
        } else {
          print("⚠️ Rating mismatch - Expected: $rating, Got: $updatedRating");
        }
      }

      await _updateUserRatingInProfile(
        targetUserId: booking.provider.id,
        newRating: rating,
      );

      print("Job Completed and Provider Rated: $rating");

    } catch (e, stacktrace) {
      print("❌ Error in completeAndRateTask: $e");
      print("Stacktrace: $stacktrace");
      rethrow;
    }
  }

  static Future<void> submitRatingForCustomer({
    required String bookingId,
    required String customerId,
    required double rating,
  }) async {
    try {
      await _supabase.from('bookings').update({
        'customer_rating': rating,
      }).eq('id', bookingId);

      await _updateUserRatingInProfile(
        targetUserId: customerId,
        newRating: rating,
      );

      print("Customer Rated by Provider: $rating");
    } catch (e) {
      print("Error in submitRatingForCustomer: $e");
    }
  }

  static Future<void> _updateUserRatingInProfile({
    required String targetUserId,
    required double newRating,
  }) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('average_rating, total_reviews')
          .eq('id', targetUserId)
          .single();

      double currentAvg = (userData['average_rating'] as num?)?.toDouble() ?? 5.0;
      int totalReviews = (userData['total_reviews'] as int?) ?? 0;

      int newTotalReviews = totalReviews + 1;
      double newAverage = ((currentAvg * totalReviews) + newRating) / newTotalReviews;

      await _supabase.from('users').update({
        'average_rating': newAverage,
        'total_reviews': newTotalReviews,
      }).eq('id', targetUserId);
    } catch (e) {
      print("Profile Rating Update Error: $e");
    }
  }

  static Future<Map<String, dynamic>> getCustomerRatingData(String customerId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('average_rating, total_reviews')
          .eq('id', customerId)
          .single();
      return {
        'average_rating': (data['average_rating'] as num?)?.toDouble() ?? 5.0,
        'total_reviews': data['total_reviews'] ?? 0,
      };
    } catch (e) {
      print("Get Customer Rating Error: $e");
      return {'average_rating': 5.0, 'total_reviews': 0};
    }
  }

  // ================= CHAT LOGIC =================
  static Future<void> sendMessage(MessageModel message) async {
    try {
      final messageData = message.toMap();
      messageData.remove('id');
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
        id: '',
        bookingId: booking.id,
        senderId: booking.customerId,
        receiverId: booking.provider.id,
        content: "Hi ${booking.provider.name}, I have booked your service.",
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      await sendMessage(autoMsg);
    } catch (e) {
      print("Auto Message Error: $e");
    }
  }
}