import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/provider_model.dart';
import '../models/message_model.dart';

class StorageService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= PROVIDER LOGIC =================
  static Future<void> saveProvider(ProviderModel provider) async {
    await _db.collection('users').doc(provider.id).set(provider.toMap());
  }

  static Stream<List<ProviderModel>> getProvidersStream() {
    return _db.collection('users')
        .where('profession', isNotEqualTo: 'Customer')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ProviderModel.fromMap(doc.data()))
        .toList());
  }

  // ================= BOOKING LOGIC =================
  static Future<void> saveBooking(BookingModel booking) async {
    await _db.collection('bookings').doc(booking.id).set(booking.toMap());
    await sendAutoWelcomeMessage(booking);
  }

  static Stream<List<BookingModel>> getBookingsStream(String userId, bool isProvider) {
    return _db.collection('bookings')
        .where(isProvider ? 'provider.id' : 'customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data(), docId: doc.id))
        .toList());
  }

  static Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    return getBookingsStream(userId, false);
  }

  static Future<void> updateBookingStatus(String id, String newStatus) async {
    await _db.collection('bookings').doc(id).update({'status': newStatus});
  }

  static Future<void> deleteBooking(String id) async {
    await deleteFullConversation(id);
    await _db.collection('bookings').doc(id).delete();
  }

  // ================= CHAT LOGIC =================
  static Stream<List<BookingModel>> getProviderChatsStream(String userId) {
    return getBookingsStream(userId, true);
  }

  static Future<void> sendMessage(MessageModel message) async {
    // Har message ko booking ke andar 'messages' sub-collection mein save karna
    await _db.collection('bookings')
        .doc(message.bookingId)
        .collection('messages')
        .add(message.toMap());
  }

  static Stream<List<MessageModel>> getChatStream(String bookingId) {
    return _db.collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data(), docId: doc.id))
        .toList());
  }

  static Future<void> deleteFullConversation(String bookingId) async {
    var messages = await _db.collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> sendAutoWelcomeMessage(BookingModel booking) async {
    final autoMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: booking.id,
      senderId: booking.customerId,
      receiverId: booking.provider.id,
      content: "Hi ${booking.provider.name}, I have booked your service for ${booking.date}. Let's discuss!",
      timestamp: DateTime.now(),
      type: MessageType.text, // Ensure enum type is passed
    );
    await sendMessage(autoMsg);
  }

  // FIX: currentUserId add kiya gaya hai taake sirf wahi messages "seen" hon jo receiver ke hon
  static Future<void> markAsSeen(String bookingId, String currentUserId) async {
    var query = await _db.collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isSeen', isEqualTo: false)
        .get();

    WriteBatch batch = _db.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isSeen': true});
    }
    await batch.commit(); // Batch use karne se performance behter hoti hai
  }
}