import 'user.dart';
import 'product.dart';

class Feedback {
  final String id;
  final User user;
  final String productId; // Đổi từ Product sang String
  final String comment;
  final double rating;
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.user,
    required this.productId,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['_id'],
      user: User.fromJson(json['userId']),
      productId: json['productId'] is Map
          ? json['productId']['_id']
          : json['productId'].toString(),
      comment: json['comment'] ?? '',
      rating: (json['rating'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
