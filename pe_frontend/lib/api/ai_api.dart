import 'package:pe_frontend/api/api_client.dart';


class AIApi {
  static Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? productId,
    String? token,
  }) async {
    return await ApiClient.post(
      '/v1/ai/send-message',
      {
        'message': message,
        if (productId != null) 'productId': productId,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getChatHistory({
    String? productId,
    String? token,
  }) async {
    final queryParams = <String, String>{};
    if (productId != null) {
      queryParams['productId'] = productId;
    }

    return await ApiClient.get(
      '/v1/ai/chat-history',
      token: token,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  static Future<Map<String, dynamic>> clearChatHistory({
    String? productId,
    String? token,
  }) async {
    return await ApiClient.post(
      '/v1/ai/clear-history',
      {
        if (productId != null) 'productId': productId,
      },
      token: token,
    );
  }
}
