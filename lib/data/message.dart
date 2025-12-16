class Message {
  final String id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json, {String? id}) {
    final messageId = id ?? json['id'].toString();
    
    return Message(
      id: messageId,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: (json['is_read'] as int) == 1,
    );
  }

  factory Message.fromDatabaseRow(Map<String, dynamic> row) {
    return Message.fromJson(row, id: row['id'].toString());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead ? 1 : 0,
      };
}

