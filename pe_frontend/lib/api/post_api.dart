import 'dart:convert';
import 'dart:io';

import 'api_client.dart';
import '../models/post.dart';
import '../session/user_session.dart';

class PostApi {
  static Future<List<Post>> fetchFeed() async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get('/v1/posts', token: token);
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to fetch feed.';
      throw ApiException(statusCode: 0, message: message);
    }
    final data = json['data'] as List<dynamic>? ?? <dynamic>[];
    return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Post> createPost(String content, {File? imageFile}) async {
    final token = UserSession.instance.accessToken;
    String image = '';
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
    final json = await ApiClient.post('/v1/posts', {
      'content': content,
      'image': image,
    }, token: token);
    return _extractPost(json, fallbackMessage: 'Failed to create post.');
  }

  static Future<Post> react({
    required String postId,
    required String type,
  }) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.post('/v1/posts/$postId/reactions', {
      'type': type,
    }, token: token);
    return _extractPost(json, fallbackMessage: 'Failed to update reaction.');
  }

  static Future<Post> comment({
    required String postId,
    required String content,
    File? imageFile,
  }) async {
    final token = UserSession.instance.accessToken;
    String image = '';
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
    final json = await ApiClient.post('/v1/posts/$postId/comments', {
      'content': content,
      'image': image,
    }, token: token);
    return _extractPost(json, fallbackMessage: 'Failed to add comment.');
  }

  static Future<Post> reply({
    required String postId,
    required String commentId,
    required String content,
    File? imageFile,
  }) async {
    final token = UserSession.instance.accessToken;
    String image = '';
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
    final json = await ApiClient.post(
      '/v1/posts/$postId/comments/$commentId/replies',
      {'content': content, 'image': image},
      token: token,
    );
    return _extractPost(json, fallbackMessage: 'Failed to add reply.');
  }

  static Future<Post> reactComment({
    required String postId,
    required String commentId,
    required String type,
  }) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.post(
      '/v1/posts/$postId/comments/$commentId/reactions',
      {'type': type},
      token: token,
    );
    return _extractPost(
      json,
      fallbackMessage: 'Failed to update comment reaction.',
    );
  }

  static Post _extractPost(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? fallbackMessage;
      throw ApiException(statusCode: 0, message: message);
    }
    final data = json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return Post.fromJson(data);
  }
}
