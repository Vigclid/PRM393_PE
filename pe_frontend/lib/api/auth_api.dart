import 'api_client.dart';
import '../models/login_response.dart';

class AuthApi {
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await ApiClient.post('/login', {
      'email': email,
      'password': password,
    });
    return LoginResponse.fromJson(json);
  }
}
