import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'feed_screen.dart' show handleLogout;

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _monthAbbr = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Numbers shown on the Statistics screen, computed from the live
/// `incident_reports` collection.
class _Stats {
  final int total;
  final int active;
  final int underReview;
  final int resolved;

  /// Reports per month for the last 6 months, oldest first. The last entry
  /// is the current month.
  final List<int> monthlyCounts;
  final List<String> monthLabels;

  /// Incident types with their counts, most common first.
  final List<MapEntry<String, int>> byType;

  const _Stats({
    required this.total,
    required this.active,
    required this.underReview,
    required this.resolved,
    required this.monthlyCounts,
    required this.monthLabels,
    required this.byType,
  });

  int get thisMonth => monthlyCounts[5];
  int get lastMonth => monthlyCounts[4];

  factory _Stats.from(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime now,
  ) {
    int active = 0;
    int underReview = 0;
    int resolved = 0;
    final monthly = List<int>.filled(6, 0);
    final typeCounts = <String, int>{};

    for (final doc in docs) {
      final data = doc.data();

      // Same rule as My Reports: a missing status counts as Active.
      switch (data['status']) {
        case 'Under Review':
          underReview++;
          break;
        case 'Resolved':
          resolved++;
          break;
        default:
          active++;
      }

      // A just-submitted report can briefly have a null server timestamp,
      // so treat a missing one as "now".
      final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? now;
      final monthsAgo = (now.year - ts.year) * 12 + (now.month - ts.month);
      if (monthsAgo >= 0 && monthsAgo < 6) {
        monthly[5 - monthsAgo]++;
      }

      final type = (data['type'] as String?) ?? 'Unknown';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    final labels = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      return _monthAbbr[d.month - 1];
    });

    final byType = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Stats(
      total: docs.length,
      active: active,
      underReview: underReview,
      resolved: resolved,
      monthlyCounts: monthly,
      monthLabels: labels,
      byType: byType,
    );
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.hexagon_outlined, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            const Text(
              'OURWATCH',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              AppColors.isDarkMode.value
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: AppColors.textSecondary,
            ),
            tooltip: AppColors.isDarkMode.value
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: () {
              AppColors.isDarkMode.value = !AppColors.isDarkMode.value;
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Sign out',
            onPressed: () => handleLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // No orderBy or where clause, so no composite index is needed.
        stream: FirebaseFirestore.instance
            .collection('incident_reports')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading statistics: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final now = DateTime.now();
          final stats = _Stats.from(snapshot.data?.docs ?? [], now);
          final resolutionRate = stats.total == 0
              ? 0.0
              : stats.resolved / stats.total;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'All reports · ${_monthNames[now.month - 1]} ${now.year}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      '${stats.total}',
                      'Total Reports',
                      'All time',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      '${stats.thisMonth}',
                      'This Month',
                      _comparisonText(stats.thisMonth, stats.lastMonth),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      '${stats.active}',
                      'Active Now',
                      'Requiring attention',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      '${stats.resolved}',
                      'Resolved',
                      'Marked by responders',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resolution Rate',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${(resolutionRate * 100).round()}%',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: resolutionRate,
                        minHeight: 6,
                        backgroundColor: AppColors.inputBg,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${stats.resolved} of ${stats.total} reports resolved'
                      ' · ${stats.underReview} under review',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTypeCard(stats),
              const SizedBox(height: 16),
              _buildMonthlyChart(stats),
            ],
          );
        },
      ),
    );
  }

  String _comparisonText(int thisMonth, int lastMonth) {
    if (lastMonth == 0) {
      return thisMonth == 0 ? 'No reports yet' : 'No reports last month';
    }
    final pct = ((thisMonth - lastMonth) / lastMonth * 100).round();
    if (pct == 0) return 'Same as last month';
    return '${pct > 0 ? '+' : ''}$pct% vs last month';
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: child,
    );
  }

  Widget _buildMetricCard(String value, String title, String subtitle) {
    // Fixed height so the cards don't balloon on a wide browser window.
    return SizedBox(
      height: 100,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(_Stats stats) {
    final maxCount = stats.byType.isEmpty ? 1 : stats.byType.first.value;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incidents by Type',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          if (stats.byType.isEmpty)
            Text(
              'No reports yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          else
            ...stats.byType.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value / maxCount,
                          minHeight: 8,
                          backgroundColor: AppColors.inputBg,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${entry.value}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(_Stats stats) {
    const maxBarHeight = 120.0;
    final maxCount = stats.monthlyCounts.reduce((a, b) => a > b ? a : b);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports Per Month',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Last 6 months',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final count = stats.monthlyCounts[i];
                final raw = maxCount == 0
                    ? 0.0
                    : count / maxCount * maxBarHeight;
                final barHeight = raw < 2 ? 2.0 : raw;
                final isCurrent = i == 5;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primaryRed
                            : AppColors.primaryRed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stats.monthLabels[i],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
