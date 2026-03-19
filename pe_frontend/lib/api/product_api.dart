import 'dart:convert';
import 'dart:io';
import 'api_client.dart';
import '../models/product.dart';
import '../session/user_session.dart';

class ProductApi {
  /// Fetches the full product list. Throws [ApiException] or [NetworkException] on failure.
  static Future<List<Product>> fetchProducts() async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get('/v1/products', token: token);
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to fetch products.';
      throw ApiException(statusCode: 0, message: message);
    }
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new product. Throws [ApiException] or [NetworkException] on failure.
  static Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required File image,
  }) async {
    final token = UserSession.instance.accessToken;
    final imageBytes = await image.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    final json = await ApiClient.post(
      '/v1/products/me',
      {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'stock': stock,
        'image': 'data:image/jpeg;base64,$imageBase64',
      },
      token: token,
    );
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to create product.';
      throw ApiException(statusCode: 0, message: message);
    }
  }

  /// Updates a product. Pass [newImage] to replace the image, or leave null to keep existing.
  static Future<void> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required String existingImageUrl,
    File? newImage,
  }) async {
    final token = UserSession.instance.accessToken;
    String imageValue = existingImageUrl;
    if (newImage != null) {
      final bytes = await newImage.readAsBytes();
      imageValue = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
    final json = await ApiClient.put(
      '/v1/products/$id',
      {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'stock': stock,
        'image': imageValue,
      },
      token: token,
    );
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to update product.';
      throw ApiException(statusCode: 0, message: message);
    }
  }

  static Future<void> deleteProduct(String id) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.delete('/v1/products/$id', token: token);
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to delete product.';
      throw ApiException(statusCode: 0, message: message);
    }
  }
}
