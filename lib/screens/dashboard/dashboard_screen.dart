import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/dashboard_model.dart';
import '../../models/expense_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
      context.read<ExpenseProvider>().fetchExpenses(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user      = context.watch<AuthProvider>().user;
    final dashProv  = context.watch<DashboardProvider>();
    final expProv   = context.watch<ExpenseProvider>();
    final currency  = user?.currency ?? 'PKR';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await context.read<DashboardProvider>().fetchDashboard();
            await context.read<ExpenseProvider>().fetchExpenses(refresh: true);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _Header(userName: user?.name ?? ''),
              ),

              // Content
              if (dashProv.loading && dashProv.dashboard == null)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (dashProv.error != null && dashProv.dashboard == null)
                SliverFillRemaining(
                  child: _ErrorView(
                    message: dashProv.error!,
                    onRetry: () => dashProv.fetchDashboard(),
                  ),
                )
              else if (dashProv.dashboard != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Budget ring card
                        _BudgetRingCard(
                          dashboard: dashProv.dashboard!,
                          currency:  currency,
                        ),
                        const SizedBox(height: 16),

                        // Stats row
                        _StatsRow(
                          dashboard: dashProv.dashboard!,
                          currency:  currency,
                        ),
                        const SizedBox(height: 24),

                        // Category breakdown
                        _SectionTitle(
                          title:   'Spending by Category',
                          onSeeAll: () => context.go('/reports'),
                        ),
                        const SizedBox(height: 12),
                        _CategoryChart(dashboard: dashProv.dashboard!),
                        const SizedBox(height: 24),

                        // Recent transactions header
                        _SectionTitle(
                          title:    'Recent Transactions',
                          onSeeAll: () => context.go('/transactions'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Recent expenses list
                if (expProv.loading && expProv.expenses.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  )
                else if (expProv.expenses.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyExpenses())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          // Show max 5 on dashboard
                          if (i >= 5 || i >= expProv.expenses.length) return null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ExpenseItem(
                              expense:  expProv.expenses[i],
                              currency: currency,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),

      // FAB - add expense
      floatingActionButton: FloatingActionButton(
        onPressed:       () => context.push('/add-expense'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

//  Header ──

class _Header extends StatelessWidget {
  final String userName;
  const _Header({required this.userName});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 13,
                  color:    AppColors.textSecondary,
                ),
              ),
              Text(
                userName.split(' ').first,
                style: const TextStyle(
                  fontSize:   22,
                  fontWeight: FontWeight.bold,
                  color:      AppColors.textPrimary,
                ),
              ),
            ],
          ),
          // Month badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppColors.border),
            ),
            child: Text(
              DateFormatter.formatMonth(DateTime.now()),
              style: const TextStyle(
                fontSize:   12,
                color:      AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//  Budget Ring Card ─

class _BudgetRingCard extends StatelessWidget {
  final DashboardModel dashboard;
  final String         currency;
  const _BudgetRingCard({required this.dashboard, required this.currency});

  @override
  Widget build(BuildContext context) {
    final ratio    = dashboard.usageRatio.clamp(0.0, 1.0);
    final isOver   = dashboard.totalSpent > dashboard.monthlyBudget;
    final ringColor = isOver ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Ring chart
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace:     0,
                    centerSpaceRadius: 65,
                    sections: [
                      PieChartSectionData(
                        value:      ratio * 100,
                        color:      ringColor,
                        radius:     20,
                        showTitle:  false,
                      ),
                      PieChartSectionData(
                        value:      (1 - ratio) * 100,
                        color:      AppColors.border,
                        radius:     20,
                        showTitle:  false,
                      ),
                    ],
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(ratio * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize:   28,
                        fontWeight: FontWeight.bold,
                        color:      ringColor,
                      ),
                    ),
                    const Text(
                      'used',
                      style: TextStyle(
                        fontSize: 12,
                        color:    AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Spent / Budget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RingLegend(
                label:  'Spent',
                amount: CurrencyFormatter.format(dashboard.totalSpent, currency: currency),
                color:  ringColor,
              ),
              _RingLegend(
                label:  'Budget',
                amount: CurrencyFormatter.format(dashboard.monthlyBudget, currency: currency),
                color:  AppColors.textSecondary,
                alignRight: true,
              ),
            ],
          ),

          if (isOver) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:        AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Over budget by ${CurrencyFormatter.format(
                      dashboard.totalSpent - dashboard.monthlyBudget,
                      currency: currency,
                    )}',
                    style: const TextStyle(
                      fontSize: 12,
                      color:    AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  final String label;
  final String amount;
  final Color  color;
  final bool   alignRight;
  const _RingLegend({
    required this.label,
    required this.amount,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(amount,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

//  Stats Row 

class _StatsRow extends StatelessWidget {
  final DashboardModel dashboard;
  final String         currency;
  const _StatsRow({required this.dashboard, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label:  'Remaining',
            amount: CurrencyFormatter.format(
              dashboard.remaining.clamp(0, double.infinity),
              currency: currency,
            ),
            color: AppColors.success,
            icon:  Icons.savings_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label:  'Transactions',
            amount: dashboard.transactionCount.toString(),
            color:  AppColors.primary,
            icon:   Icons.receipt_long_outlined,
            isCurrency: false,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color  color;
  final IconData icon;
  final bool   isCurrency;
  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding:      const EdgeInsets.all(8),
            decoration:   BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(amount,
                    style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                        color:      color),
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  Category Chart 

class _CategoryChart extends StatelessWidget {
  final DashboardModel dashboard;
  const _CategoryChart({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final breakdown = dashboard.categoryBreakdown;
    if (breakdown.isEmpty) {
      return const _EmptyExpenses();
    }

    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        children: entries.map((entry) {
          final color = AppColors.categoryColors[entry.key] ?? AppColors.primary;
          final total = breakdown.values.fold(0.0, (a, b) => a + b);
          final pct   = total > 0 ? entry.value / total : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color:  color,
                            shape:  BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(entry.key,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary)),
                      ],
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:           pct,
                    backgroundColor: AppColors.border,
                    valueColor:      AlwaysStoppedAnimation(color),
                    minHeight:       6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

//  Expense Item 

class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  final String       currency;
  const _ExpenseItem({required this.expense, required this.currency});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[expense.category] ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Category icon circle
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color:  color.withOpacity(0.15),
              shape:  BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _categoryEmoji(expense.category),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.category,
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w500,
                        color:      AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  expense.note?.isNotEmpty == true
                      ? expense.note!
                      : DateFormatter.format(expense.date),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- ${CurrencyFormatter.format(expense.amount, currency: currency)}',
                style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.error),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.formatShort(expense.date),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String category) {
    const map = {
      'Food':          '🍔',
      'Transport':     '🚗',
      'Shopping':      '🛍️',
      'Bills':         '💡',
      'Health':        '💊',
      'Entertainment': '🎬',
      'Other':         '📦',
    };
    return map[category] ?? '📦';
  }
}

//  Section Title ─

class _SectionTitle extends StatelessWidget {
  final String    title;
  final VoidCallback? onSeeAll;
  const _SectionTitle({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColors.textPrimary)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('See all',
                style: TextStyle(
                    fontSize: 13,
                    color:    AppColors.primary,
                    fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}

//  Empty / Error States 

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Text('💸', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('No expenses yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text('Tap + to add your first expense',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String       message;
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
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}