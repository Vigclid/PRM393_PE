import 'api_client.dart';
import '../models/chat.dart';
import '../session/user_session.dart';

class ChatApi {
  /// Fetches all chats for the current user (GET /v1/chats/me)
  /// Returns a list of Chat objects with populated user information
  /// Throws [ApiException] or [NetworkException] on failure
  static Future<List<Chat>> fetchChats() async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get('/v1/chats/me', token: token);
    
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to fetch chats.';
      throw ApiException(statusCode: 0, message: message);
    }
    
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => Chat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new chat with another user (POST /v1/chats/me)
  /// Returns the created Chat object
  /// Throws [ApiException] or [NetworkException] on failure
  static Future<Chat> createChat({required String user2Id}) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.post(
      '/v1/chats/me',
      {'user2Id': user2Id},
      token: token,
    );
    
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to create chat.';
      throw ApiException(statusCode: 0, message: message);
    }
    
    final data = json['data'] as Map<String, dynamic>;
    return Chat.fromJson(data);
  }

  /// Gets a chat between the current user and another user (GET /v1/chats/me/other/:userId)
  /// Returns the Chat object if it exists, null otherwise
  /// Throws [ApiException] or [NetworkException] on failure
  static Future<Chat?> getChatWith({required String userId}) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get('/v1/chats/me/other/$userId', token: token);
    
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to fetch chat.';
      throw ApiException(statusCode: 0, message: message);
    }
    
    final data = json['data'];
    if (data == null) {
      return null;
    }
    
    return Chat.fromJson(data as Map<String, dynamic>);
  }
}
