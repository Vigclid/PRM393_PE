import 'api_client.dart';
import '../models/cart.dart';
import '../session/user_session.dart';

class CartApi {
  /// Fetches the current user's cart.
  static Future<Cart> fetchCart() async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get('/v1/carts/me', token: token);
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to fetch cart.';
      throw ApiException(statusCode: 0, message: message);
    }
    return Cart.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Adds or updates a product in the cart. Pass quantity=0 to remove.
  static Future<void> updateCart({
    required String productId,
    required double priceAtTime,
    required int quantity,
  }) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.post('/v1/carts/me', {
      'productId': productId,
      'priceAtTime': priceAtTime,
      'quantity': quantity,
    }, token: token);
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to update cart.';
      throw ApiException(statusCode: 0, message: message);
    }
  }
}
