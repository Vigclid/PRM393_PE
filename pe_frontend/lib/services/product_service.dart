import '../api/product_api.dart';
import '../models/product.dart';

class ProductService {
  static Future<List<Product>> fetchProducts() => ProductApi.fetchProducts();

  static List<String> get categories => [
    'All',
    'Electronics',
    'Education',
    'Hardware',
    'Software',
  ];
}
