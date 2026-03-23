import 'package:flutter/material.dart';
import 'package:pe_frontend/api/report_api.dart';
import 'package:pe_frontend/session/user_session.dart';
import 'package:pe_frontend/theme/app_theme.dart';
import 'report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = _fetchReports();
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    try {
      final token = UserSession.instance.accessToken;
      if (token == null) return [];

      final response = await ReportApi.getMyReports(token: token);
      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error loading reports: $e');
      return [];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'InProgress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      default:
        return AppColors.gold;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Help':
        return Colors.blue;
      case 'Bug':
        return Colors.red;
      case 'Advice':
        return Colors.purple;
      default:
        return AppColors.gold;
    }
  }

  void _navigateToDetail(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(reportId: reportId),
      ),
    ).then((result) {
      if (result == true) {
        setState(() => _loadReports());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppColors.border,
        title: const Text(
          'My Reports',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.gold, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading reports',
                    style: TextStyle(color: AppColors.goldMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _loadReports()),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, color: AppColors.goldMuted, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'No reports yet',
                    style: TextStyle(color: AppColors.goldMuted),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.surface,
            onRefresh: () async => setState(() => _loadReports()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportCard(
                  report: report,
                  onTap: () => _navigateToDetail(report['_id'] ?? ''),
                  getStatusColor: _getStatusColor,
                  getTypeColor: _getTypeColor,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;
  final Color Function(String) getStatusColor;
  final Color Function(String) getTypeColor;

  const _ReportCard({
    required this.report,
    required this.onTap,
    required this.getStatusColor,
    required this.getTypeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getTypeColor(report['typeReport'] ?? 'Help').withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: getTypeColor(report['typeReport'] ?? 'Help'),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          report['typeReport'] == 'Help'
                              ? Icons.help_outline
                              : report['typeReport'] == 'Bug'
                                  ? Icons.bug_report_outlined
                                  : Icons.lightbulb_outline,
                          color: getTypeColor(report['typeReport'] ?? 'Help'),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report['typeReport'] ?? 'Help',
                          style: TextStyle(
                            color: getTypeColor(report['typeReport'] ?? 'Help'),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(report['status'] ?? 'Pending').withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: getStatusColor(report['status'] ?? 'Pending'),
                      ),
                    ),
                    child: Text(
                      report['status'] ?? 'Pending',
                      style: TextStyle(
                        color: getStatusColor(report['status'] ?? 'Pending'),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                report['title'] ?? 'Untitled',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                report['description'] ?? '',
                style: const TextStyle(
                  color: AppColors.goldMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer with date and reply count
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.goldMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report['createdAt']),
                    style: const TextStyle(color: AppColors.goldMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(Icons.chat_bubble_outline, color: AppColors.goldMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${(report['replies'] as List?)?.length ?? 0} replies',
                    style: const TextStyle(color: AppColors.goldMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
