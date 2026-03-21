import 'user.dart';
import 'product.dart';

class Feedback {
  final String id;
  final User user;
  final Product product;
  final String comment;
  final double rating;
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.user,
    required this.product,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['_id'],
      user: User.fromJson(json['userId']),
      product: Product.fromJson(json['productId']),
      comment: json['comment'],
      rating: json['rating'] as double,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
