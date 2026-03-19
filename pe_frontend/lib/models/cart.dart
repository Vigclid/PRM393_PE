import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final double priceAtTime;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.priceAtTime,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] as String,
      product: Product.fromJson(json['productId'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      priceAtTime: (json['priceAtTime'] as num).toDouble(),
    );
  }

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    product: product,
    quantity: quantity ?? this.quantity,
    priceAtTime: priceAtTime,
  );

  double get subtotal => priceAtTime * quantity;
}

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;

  const Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>)
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return Cart(
      id: data['_id'] as String,
      userId: data['userId'] as String,
      items: items,
      totalPrice: (data['totalPrice'] as num).toDouble(),
    );
  }
}
