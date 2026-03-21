import 'dart:io';
import 'package:pe_frontend/session/user_session.dart';
import 'api_client.dart';
import '../models/feedback.dart';

class FeedbackApi {
  static Future<void> createNewFeedback({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.post('/v1/feedbacks/', {
      'productId': productId,
      'rating': rating.toInt(),
      'comment': comment,
    }, token: token);
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to create product.';
      throw ApiException(statusCode: 0, message: message);
    }
  }

  static Future<dynamic> getAverageRating(String productId) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get(
      '/v1/feedbacks/average/$productId',
      token: token,
    );
    final status = json['status'] as String?;
    if (status != 'success') {
      final message =
          json['message'] as String? ?? 'Failed to get average rating.';
      throw ApiException(statusCode: 0, message: message);
    }
    return json['data'] as double;
  }
}
