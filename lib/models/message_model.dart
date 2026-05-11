enum MessageType { text, audio, video, image }

class MessageModel {
  final String id;
  final String bookingId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  bool isSeen;

  MessageModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isSeen = false,
  });

  // --- SUPABASE MEIN SAVE KARNE KE LIYE ---
  Map<String, dynamic> toMap() {
    return {
      // 'id' hum aksar omit kar dete hain agar Supabase UUID generate kar raha ho
      'booking_id': bookingId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': type.index, // 'type' reserved word ho sakta hai SQL mein
      'created_at': timestamp.toIso8601String(), // Standard Supabase naming
      'is_seen': isSeen,
    };
  }

  // --- SUPABASE SE DATA LENE KE LIYE ---
  factory MessageModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return MessageModel(
      id: docId ?? (map['id']?.toString() ?? ''),
      bookingId: map['booking_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      receiverId: map['receiver_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',

      // Enum Safety: Supabase se index int ki tarah aata hai
      type: (map['message_type'] != null && map['message_type'] < MessageType.values.length)
          ? MessageType.values[map['message_type']]
          : MessageType.text,

      // Supabase hamesha ISO8601 String bhejta hai
      timestamp: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),

      isSeen: map['is_seen'] ?? false,
    );
  }

  MessageModel copyWith({bool? isSeen}) {
    return MessageModel(
      id: id,
      bookingId: bookingId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      timestamp: timestamp,
      isSeen: isSeen ?? this.isSeen,
    );
  }
}