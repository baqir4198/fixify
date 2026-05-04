enum MessageType { text, audio, video }

class MessageModel {
  final String id;
  final String bookingId;
  final String senderId;
  final String receiverId;
  final String content; // Text message ya file ka path
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
      'id': id,
      'bookingId': bookingId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index, // Enum ko number mein save karenge
      'timestamp': timestamp.toIso8601String(),
      'isSeen': isSeen,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      bookingId: map['bookingId'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      type: MessageType.values[map['type']],
      timestamp: DateTime.parse(map['timestamp']),
      isSeen: map['isSeen'] ?? false,
    );
  }
}