import 'package:flutter/material.dart';
import 'package:pe_frontend/api/report_api.dart';
import 'package:pe_frontend/session/user_session.dart';
import 'package:pe_frontend/theme/app_theme.dart';
import 'report_detail_screen.dart';

class ReportSupportListScreen extends StatefulWidget {
  const ReportSupportListScreen({super.key});

  @override
  State<ReportSupportListScreen> createState() => _ReportSupportListScreenState();
}

class _ReportSupportListScreenState extends State<ReportSupportListScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = _fetchAllReports();
  }

  Future<List<Map<String, dynamic>>> _fetchAllReports() async {
    try {
      final token = UserSession.instance.accessToken;
      if (token == null) return [];

      final response = await ReportApi.getAllReports(token: token);
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
          'Support Reports',
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

          // Filter reports
          final filteredReports = _filterStatus == 'All'
              ? reports
              : reports.where((r) => r['status'] == _filterStatus).toList();

          return Column(
            children: [
              // Filter chips
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filterStatus == 'All',
                        onTap: () => setState(() => _filterStatus = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        selected: _filterStatus == 'Pending',
                        onTap: () => setState(() => _filterStatus = 'Pending'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'In Progress',
                        selected: _filterStatus == 'InProgress',
                        onTap: () => setState(() => _filterStatus = 'InProgress'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Resolved',
                        selected: _filterStatus == 'Resolved',
                        onTap: () => setState(() => _filterStatus = 'Resolved'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Closed',
                        selected: _filterStatus == 'Closed',
                        onTap: () => setState(() => _filterStatus = 'Closed'),
                      ),
                    ],
                  ),
                ),
              ),
              // Reports list
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async => setState(() => _loadReports()),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredReports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return _ReportCard(
                        report: report,
                        onTap: () => _navigateToDetail(report['_id'] ?? ''),
                        getStatusColor: _getStatusColor,
                        getTypeColor: _getTypeColor,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.onGold : AppColors.goldMuted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
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

              // Footer with user and reply count
              Row(
                children: [
                  const Icon(Icons.person_outline, color: AppColors.goldMuted, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report['userId'] is Map
                          ? report['userId']['email'] ?? 'Unknown'
                          : 'Unknown',
                      style: const TextStyle(color: AppColors.goldMuted, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
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
}
