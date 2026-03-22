import 'package:pe_frontend/api/api_client.dart';

class ReportApi {
  static Future<Map<String, dynamic>> createReport({
    required String typeReport,
    required String title,
    required String description,
    required String token,
  }) async {
    return await ApiClient.post(
      '/v1/report',
      {
        'typeReport': typeReport,
        'title': title,
        'description': description,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getMyReports({
    required String token,
  }) async {
    return await ApiClient.get(
      '/v1/report',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getReportById({
    required String reportId,
    required String token,
  }) async {
    return await ApiClient.get(
      '/v1/report/$reportId',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> addReply({
    required String reportId,
    required String message,
    required String token,
  }) async {
    return await ApiClient.post(
      '/v1/report/$reportId/reply',
      {'message': message},
      token: token,
    );
  }
}
