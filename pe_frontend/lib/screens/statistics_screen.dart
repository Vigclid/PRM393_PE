import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/bill_api.dart';
import '../session/user_session.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _filterType = 'day';
  RevenueStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await BillApi.getRevenueStatistics(type: _filterType);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load statistics. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _onLogout() async {
    await UserSession.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _setFilter(String type) {
    if (_filterType == type) return;
    setState(() => _filterType = type);
    _loadStats();
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
        automaticallyImplyLeading: false,
        title: const Text(
          'XS App',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _onLogout,
            icon: const Icon(
              Icons.logout,
              color: AppColors.goldMuted,
              size: 18,
            ),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppColors.goldMuted),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterBar(selected: _filterType, onSelect: _setFilter),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.gold, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.goldMuted)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_stats == null || _stats!.breakdown.isEmpty) {
      return const Center(
        child: Text(
          'No data for this period.',
          style: TextStyle(color: AppColors.goldMuted, fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _TotalRevenueCard(total: _stats!.totalRevenue),
        const SizedBox(height: 20),
        const Text(
          'Breakdown',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        ..._stats!.breakdown.map((item) => _BreakdownRow(item: item)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------
class _FilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _FilterChip(
            label: 'Day',
            value: 'day',
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Month',
            value: 'month',
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Year',
            value: 'year',
            selected: selected,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onSelect;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.onGold : AppColors.goldMuted,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total revenue card
// ---------------------------------------------------------------------------
class _TotalRevenueCard extends StatelessWidget {
  final double total;

  const _TotalRevenueCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Revenue',
            style: TextStyle(color: AppColors.goldMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breakdown row
// ---------------------------------------------------------------------------
class _BreakdownRow extends StatelessWidget {
  final RevenueBreakdown item;

  const _BreakdownRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.period,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.totalRevenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                '${item.totalOrders} order${item.totalOrders == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.goldMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
