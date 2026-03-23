class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime dateSent;
  final int isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.dateSent,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      message: json['message'] as String,
      dateSent: DateTime.parse(json['dateSent'] as String),
      isRead: json['isRead'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'dateSent': dateSent.toIso8601String(),
        'isRead': isRead,
      };
}
