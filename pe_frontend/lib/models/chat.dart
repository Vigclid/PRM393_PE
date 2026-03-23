import 'user.dart';
import 'message.dart';

class Chat {
  final String id;
  final User user1;
  final User user2;
  final int status;
  final Message? lastMessage;

  Chat({
    required this.id,
    required this.user1,
    required this.user2,
    required this.status,
    this.lastMessage,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'] as String,
      user1: User.fromJson(json['user1Id'] as Map<String, dynamic>),
      user2: User.fromJson(json['user2Id'] as Map<String, dynamic>),
      status: json['status'] as int,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'user1Id': user1.toJson(),
        'user2Id': user2.toJson(),
        'status': status,
        'lastMessage': lastMessage?.toJson(),
      };
}
