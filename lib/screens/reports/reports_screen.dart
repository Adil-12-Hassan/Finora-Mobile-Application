import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashProv = context.watch<DashboardProvider>();
    final currency = context.watch<AuthProvider>().user?.currency ?? 'PKR';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _MonthSelector(
                    month: dashProv.month,
                    onChanged: (m) => dashProv.setMonth(m),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Daily Trend'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: dashProv.loading && dashProv.dashboard == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : dashProv.error != null && dashProv.dashboard == null
                  ? _ErrorView(
                      message: dashProv.error!,
                      onRetry: () => dashProv.fetchDashboard(),
                    )
                  : dashProv.dashboard == null
                  ? const SizedBox()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(
                          dashboard: dashProv.dashboard!,
                          currency: currency,
                        ),
                        _DailyTrendTab(
                          dashboard: dashProv.dashboard!,
                          currency: currency,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Overview Tab 

class _OverviewTab extends StatefulWidget {
  final DashboardModel dashboard;
  final String currency;
  const _OverviewTab({required this.dashboard, required this.currency});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final breakdown = widget.dashboard.categoryBreakdown;
    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (breakdown.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => context.read<DashboardProvider>().fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Pie chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'Spending Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 50,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex =
                                  response.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: entries.asMap().entries.map((e) {
                          final i = e.key;
                          final entry = e.value;
                          final isTouched = i == _touchedIndex;
                          final color =
                              AppColors.categoryColors[entry.key] ??
                              AppColors.primary;
                          final pct = total > 0
                              ? (entry.value / total * 100)
                              : 0.0;

                          return PieChartSectionData(
                            value: entry.value,
                            color: color,
                            radius: isTouched ? 65 : 55,
                            showTitle: isTouched,
                            title: '${pct.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: entries.map((entry) {
                      final color =
                          AppColors.categoryColors[entry.key] ??
                          AppColors.primary;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category breakdown list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'By Category',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...entries.map((entry) {
                    final color =
                        AppColors.categoryColors[entry.key] ??
                        AppColors.primary;
                    final pct = total > 0 ? entry.value / total : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(
                                      entry.value,
                                      currency: widget.currency,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${(pct * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Summary card
            const SizedBox(height: 16),
            _SummaryCard(
              dashboard: widget.dashboard,
              currency: widget.currency,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

//  Daily Trend Tab ──

class _DailyTrendTab extends StatelessWidget {
  final DashboardModel dashboard;
  final String currency;
  const _DailyTrendTab({required this.dashboard, required this.currency});

  @override
  Widget build(BuildContext context) {
    final daily = dashboard.dailySpend;
    if (daily.isEmpty) return const _EmptyState();

    final maxY = daily.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final spots = daily.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.amount);
    }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => context.read<DashboardProvider>().fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Line chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Spending',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY * 1.2,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4,
                          getDrawingHorizontalLine: (_) =>
                              FlLine(color: AppColors.border, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              interval: maxY / 4,
                              getTitlesWidget: (val, _) => Text(
                                val >= 1000
                                    ? '${(val / 1000).toStringAsFixed(0)}k'
                                    : val.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: (daily.length / 5).ceilToDouble(),
                              getTitlesWidget: (val, _) {
                                final i = val.toInt();
                                if (i >= daily.length) {
                                  return const SizedBox();
                                }
                                final parts = daily[i].date.split('-');
                                return Text(
                                  parts.length >= 3 ? parts[2] : '',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots
                                .map(
                                  (s) => LineTooltipItem(
                                    CurrencyFormatter.format(
                                      s.y,
                                      currency: currency,
                                    ),
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (_, __, ___, ____) =>
                                  FlDotCirclePainter(
                                    radius: 3,
                                    color: AppColors.primary,
                                    strokeWidth: 1.5,
                                    strokeColor: Colors.white,
                                  ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Day by Day',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...daily.reversed.map((d) {
                    final date = DateTime.parse(d.date);
                    final ratio = maxY > 0 ? d.amount / maxY : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              DateFormatter.formatShort(date).split(' ')[1],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            CurrencyFormatter.format(
                              d.amount,
                              currency: currency,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

//  Summary Card 

class _SummaryCard extends StatelessWidget {
  final DashboardModel dashboard;
  final String currency;
  const _SummaryCard({required this.dashboard, required this.currency});

  @override
  Widget build(BuildContext context) {
    final daily = dashboard.dailySpend;
    final avgDaily = daily.isNotEmpty
        ? dashboard.totalSpent / daily.length
        : 0.0;
    final topEntry = dashboard.categoryBreakdown.entries.isEmpty
        ? null
        : dashboard.categoryBreakdown.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Total Spent',
            value: CurrencyFormatter.format(
              dashboard.totalSpent,
              currency: currency,
            ),
          ),
          _SummaryRow(
            label: 'Monthly Budget',
            value: CurrencyFormatter.format(
              dashboard.monthlyBudget,
              currency: currency,
            ),
          ),
          _SummaryRow(
            label: 'Remaining',
            value: CurrencyFormatter.format(
              dashboard.remaining.clamp(0, double.infinity),
              currency: currency,
            ),
            valueColor: AppColors.success,
          ),
          _SummaryRow(
            label: 'Avg. Daily Spend',
            value: CurrencyFormatter.format(avgDaily, currency: currency),
          ),
          if (topEntry != null)
            _SummaryRow(
              label: 'Top Category',
              value: topEntry.key,
              valueColor:
                  AppColors.categoryColors[topEntry.key] ?? AppColors.primary,
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

//  Month Selector 

class _MonthSelector extends StatelessWidget {
  final String month;
  final Function(String) onChanged;
  const _MonthSelector({required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final parts = month.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            final prev = DateTime(date.year, date.month - 1);
            onChanged(DateFormatter.toMonthKey(prev));
          },
          child: const Icon(
            Icons.chevron_left,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            DateFormatter.formatMonth(date),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            final now = DateTime.now();
            final next = DateTime(date.year, date.month + 1);
            if (next.isBefore(DateTime(now.year, now.month + 1))) {
              onChanged(DateFormatter.toMonthKey(next));
            }
          },
          child: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

//  Empty / Error States 

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📊', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'No data for this month',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add some expenses to see reports',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
