import 'api_client.dart';
import '../models/message.dart';
import '../session/user_session.dart';

class MessageApi {
  /// Fetches all messages for a specific chat (GET /v1/messages/chat/:chatId)
  /// Returns a list of Message objects ordered by timestamp
  /// Throws [ApiException] or [NetworkException] on failure
  static Future<List<Message>> fetchMessages(String chatId) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get('/v1/messages/chat/$chatId', token: token);
    
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to fetch messages.';
      throw ApiException(statusCode: 0, message: message);
    }
    
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Marks a message as read (PUT /v1/messages/:messageId/read)
  /// Returns void on success
  /// Throws [ApiException] or [NetworkException] on failure
  static Future<void> markAsRead(String messageId) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.put(
      '/v1/messages/$messageId/read',
      {},
      token: token,
    );
    
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to mark message as read.';
      throw ApiException(statusCode: 0, message: message);
    }
  }

  /// Gets the unread message count for the current user (GET /v1/messages/unread-count)
  /// Returns the count as an integer
  /// Throws [ApiException] or [NetworkException] on failure
  static Future<int> getUnreadCount() async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get('/v1/messages/unread-count', token: token);
    
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to get unread count.';
      throw ApiException(statusCode: 0, message: message);
    }
    
    final data = json['data'] as Map<String, dynamic>;
    return data['count'] as int;
  }
}
