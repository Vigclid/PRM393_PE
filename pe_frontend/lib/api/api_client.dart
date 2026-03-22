import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Thrown when the server returns a non-2xx status code.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown on network-level failures (no connection, timeout, etc).
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  static const String baseUrl = 'http://192.168.1.79:8080';

  static Map<String, String> _headers({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// POST request. Returns the decoded JSON body on success.
  /// Throws [ApiException] on HTTP errors, [NetworkException] on connectivity issues.
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .post(
            uri,
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const NetworkException(
        'Request timed out. Please check your connection and try again.',
      );
    } on HttpException {
      throw const NetworkException(
        'Could not reach the server. Please try again.',
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// GET request. Returns the decoded JSON body on success.
  static Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const NetworkException(
        'Request timed out. Please check your connection and try again.',
      );
    } on HttpException {
      throw const NetworkException(
        'Could not reach the server. Please try again.',
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// PUT request. Returns the decoded JSON body on success.
  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .put(
            uri,
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const NetworkException(
        'Request timed out. Please check your connection and try again.',
      );
    } on HttpException {
      throw const NetworkException(
        'Could not reach the server. Please try again.',
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// DELETE request. Returns the decoded JSON body on success.
  static Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .delete(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const NetworkException(
        'Request timed out. Please check your connection and try again.',
      );
    } on HttpException {
      throw const NetworkException(
        'Could not reach the server. Please try again.',
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Multipart POST (for file uploads). Returns the decoded JSON body on success.
  static Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required File file,
    required String fileField,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath(fileField, file.path),
      );
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const NetworkException(
        'Request timed out. Please check your connection and try again.',
      );
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] as String? ?? 'Something went wrong.';
    throw ApiException(statusCode: response.statusCode, message: message);
  }
}
