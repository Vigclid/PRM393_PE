import 'package:pe_frontend/api/api_client.dart';
import 'package:pe_frontend/session/user_session.dart';

class RevenueBreakdown {
  final String period;
  final double totalRevenue;
  final int totalOrders;

  const RevenueBreakdown({
    required this.period,
    required this.totalRevenue,
    required this.totalOrders,
  });
}

class RevenueStats {
  final double totalRevenue;
  final List<RevenueBreakdown> breakdown;

  const RevenueStats({required this.totalRevenue, required this.breakdown});
}

class BillApi {
  static Future<void> checkout() async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.post('/v1/bills/me', {}, token: token);
    final status = json['status'] as String?;
    if (status != 'success') {
      final message = json['message'] as String? ?? 'Failed to checkout.';
      throw ApiException(statusCode: (0), message: message);
    }
  }

  static Future<RevenueStats> getRevenueStatistics({
    String type = 'day',
  }) async {
    final token = UserSession.instance.accessToken;
    final json = await ApiClient.get(
      '/v1/bills/revenue',
      token: token,
      queryParams: {'type': type},
    );
    final data = json['data'] as Map<String, dynamic>;
    final breakdownJson = data['breakdown'] as List<dynamic>;
    return RevenueStats(
      totalRevenue: (data['totalRevenue'] as num).toDouble(),
      breakdown: breakdownJson.map((e) {
        final item = e as Map<String, dynamic>;
        return RevenueBreakdown(
          period: item['_id'] as String,
          totalRevenue: (item['totalRevenue'] as num).toDouble(),
          totalOrders: item['totalOrders'] as int,
        );
      }).toList(),
    );
  }
}
