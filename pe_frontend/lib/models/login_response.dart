import '../api/api_client.dart';
import 'user.dart';

class LoginResponse {
  final String accessToken;
  final User user;

  const LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Something went wrong.';
      throw ApiException(statusCode: 0, message: message);
    }

    final data = json['data'] as Map<String, dynamic>;
    return LoginResponse(
      accessToken: data['accessToken'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
