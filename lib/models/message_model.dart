enum MessageType { text, audio, video, image } // Maine 'image' bhi add kar diya hai future ke liye

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
      'id': id,
      'bookingId': bookingId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'isSeen': isSeen,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return MessageModel(
      id: docId ?? (map['id'] ?? ''),
      bookingId: map['bookingId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      // Safety check for Enum index
      type: (map['type'] != null && map['type'] < MessageType.values.length)
          ? MessageType.values[map['type']]
          : MessageType.text,
      // Firebase Timestamp ya ISO string dono ko handle karne ke liye
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isSeen: map['isSeen'] ?? false,
    );
  }

  // CopyWith Method: Jab message "Seen" mark karna ho toh ye kaam ayega
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