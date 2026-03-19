import 'api_client.dart';

class UserApi {
  /// Returns true if the email is already registered.
  static Future<bool> checkEmailExists(String email) async {
    final json = await ApiClient.get('/v1/users/exist/$email');
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Something went wrong.';
      throw ApiException(statusCode: 0, message: message);
    }
    final data = json['data'] as Map<String, dynamic>;
    return data['exists'] as bool? ?? false;
  }

  /// Registers a new user. Throws [ApiException] on failure.
  static Future<void> register({
    required String email,
    required String password,
  }) async {
    final json = await ApiClient.post('/v1/users', {
      'email': email,
      'password': password,
    });
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Registration failed.';
      throw ApiException(statusCode: 0, message: message);
    }
  }
}
