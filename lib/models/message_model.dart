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

 Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': type.index,
      'created_at': timestamp.toIso8601String(),
      'is_seen': isSeen,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return MessageModel(
      id: docId ?? (map['id']?.toString() ?? ''),
      bookingId: map['booking_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      receiverId: map['receiver_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',

      type: (map['message_type'] != null && map['message_type'] < MessageType.values.length)
          ? MessageType.values[map['message_type']]
          : MessageType.text,

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