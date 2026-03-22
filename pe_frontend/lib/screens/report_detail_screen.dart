import 'package:flutter/material.dart';
import 'package:pe_frontend/api/report_api.dart';
import 'package:pe_frontend/session/user_session.dart';
import 'package:pe_frontend/theme/app_theme.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<Map<String, dynamic>> _reportFuture;
  final _replyController = TextEditingController();
  bool _sendingReply = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = UserSession.instance.currentUser?.id ?? '';
    _loadReport();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _loadReport() {
    _reportFuture = _fetchReport();
  }

  Future<Map<String, dynamic>> _fetchReport() async {
    try {
      final token = UserSession.instance.accessToken;
      if (token == null) {
        debugPrint('No token available');
        return {};
      }

      final response = await ReportApi.getReportById(
        reportId: widget.reportId,
        token: token,
      );

      debugPrint('Report response: $response');

      if (response['status'] == 'success' && response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }
      return {};
    } catch (e) {
      debugPrint('Error loading report: $e');
      return {};
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.isEmpty) {
      _showError('Please enter a message');
      return;
    }

    setState(() => _sendingReply = true);
    try {
      final token = UserSession.instance.accessToken;
      if (token == null) {
        _showError('Please login first');
        return;
      }

      debugPrint('Sending reply to report: ${widget.reportId}');
      debugPrint('Message: ${_replyController.text}');

      final response = await ReportApi.addReply(
        reportId: widget.reportId,
        message: _replyController.text,
        token: token,
      );

      debugPrint('Reply response: $response');

      if (response['status'] == 'success') {
        _replyController.clear();
        setState(() => _loadReport());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(response['message'] ?? 'Failed to send reply');
      }
    } catch (e) {
      debugPrint('Error sending reply: $e');
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Help':
        return Icons.help_outline;
      case 'Bug':
        return Icons.bug_report_outlined;
      case 'Advice':
        return Icons.lightbulb_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
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
          'Report Details',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.gold, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading report',
                    style: TextStyle(color: AppColors.goldMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _loadReport()),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final report = snapshot.data!;
          final replies = (report['replies'] as List?) ?? [];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getTypeColor(report['typeReport'] ?? 'Help').withOpacity(0.15),
                              _getTypeColor(report['typeReport'] ?? 'Help').withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getTypeColor(report['typeReport'] ?? 'Help').withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(report['typeReport'] ?? 'Help').withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getTypeColor(report['typeReport'] ?? 'Help'),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getTypeIcon(report['typeReport'] ?? 'Help'),
                                        color: _getTypeColor(report['typeReport'] ?? 'Help'),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        report['typeReport'] ?? 'Help',
                                        style: TextStyle(
                                          color: _getTypeColor(report['typeReport'] ?? 'Help'),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(report['status'] ?? 'Pending').withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getStatusColor(report['status'] ?? 'Pending'),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(report['status'] ?? 'Pending'),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        report['status'] ?? 'Pending',
                                        style: TextStyle(
                                          color: _getStatusColor(report['status'] ?? 'Pending'),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              report['title'] ?? 'Untitled',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              report['description'] ?? '',
                              style: const TextStyle(
                                color: AppColors.goldMuted,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.goldMuted,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(report['createdAt']),
                                  style: const TextStyle(
                                    color: AppColors.goldMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppColors.goldMuted,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${replies.length} replies',
                                  style: const TextStyle(
                                    color: AppColors.goldMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Conversation Section
                      const Text(
                        'Conversation',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Admin replies (left side for admin, right side for user)
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (replies.isNotEmpty)
                              ...replies.map((reply) {
                                final senderId = reply['senderId'] is Map
                                    ? reply['senderId']['_id'] ?? ''
                                    : reply['senderId'] ?? '';
                                final isCurrentUserMessage = senderId == _currentUserId;
                                final senderEmail = reply['senderId'] is Map
                                    ? reply['senderId']['email'] ?? 'Admin'
                                    : 'Admin';
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Align(
                                    alignment: isCurrentUserMessage
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: _ChatBubble(
                                      message: reply['message'] ?? '',
                                      isUser: isCurrentUserMessage,
                                      date: _formatDate(reply['createdAt']),
                                      senderName: !isCurrentUserMessage ? senderEmail : null,
                                    ),
                                  ),
                                );
                              }).toList()
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        color: AppColors.goldMuted,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Waiting for admin response...',
                                        style: TextStyle(
                                          color: AppColors.goldMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Reply Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        maxLines: null,
                        style: const TextStyle(color: AppColors.gold),
                        decoration: InputDecoration(
                          hintText: 'Add a reply...',
                          hintStyle: const TextStyle(color: AppColors.goldMuted),
                          prefixIcon: const Icon(Icons.message_outlined, color: AppColors.goldMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gold, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        enabled: !_sendingReply,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendingReply ? null : _sendReply,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold,
                              AppColors.gold.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _sendingReply
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onGold),
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: AppColors.onGold,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String date;
  final String? senderName;

  const _ChatBubble({
    required this.message,
    required this.isUser,
    required this.date,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUser
                  ? [
                      AppColors.surface,
                      AppColors.surface.withOpacity(0.8),
                    ]
                  : [
                      AppColors.gold.withOpacity(0.15),
                      AppColors.gold.withOpacity(0.08),
                    ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isUser ? 4 : 14),
              topRight: Radius.circular(isUser ? 14 : 4),
              bottomLeft: const Radius.circular(14),
              bottomRight: const Radius.circular(14),
            ),
            border: Border.all(
              color: isUser ? AppColors.border : AppColors.gold.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              if (!isUser && senderName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.goldMuted,
                  fontSize: 14,
                  height: 1.6,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            date,
            style: const TextStyle(
              color: AppColors.goldMuted,
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}
