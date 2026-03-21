import 'api_client.dart';
import '../models/app_notification.dart';
import '../session/user_session.dart';

class NotificationApi {
  static Future<List<AppNotification>> fetchMyNotifications() async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get('/v1/notifications/me', token: token);
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to fetch notifications.';
      throw ApiException(statusCode: 0, message: message);
    }
    final data = json['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markAllRead() async {
    final token = UserSession.instance.accessToken;
    await ApiClient.put('/v1/notifications/me/read', {}, token: token);
  }
}
