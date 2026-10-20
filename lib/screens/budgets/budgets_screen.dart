import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/budget_model.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().fetchBudgets();
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  void _showSetBudgetSheet({BudgetModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SetBudgetSheet(existing: existing),
    );
  }

  Future<void> _deleteBudget(BudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Budget',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove budget for ${budget.category}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<BudgetProvider>().deleteBudget(budget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProv = context.watch<BudgetProvider>();
    final dashProv = context.watch<DashboardProvider>();
    final currency = context.watch<AuthProvider>().user?.currency ?? 'PKR';

    // Merge spent amounts from dashboard into budgets
    final budgets = _mergeBudgetsWithSpent(
      budgetProv.budgets,
      dashProv.dashboard?.categoryBreakdown ?? {},
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budgets',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      _MonthBadge(month: budgetProv.month),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _showSetBudgetSheet(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Overall budget card
            if (dashProv.dashboard != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _OverallBudgetCard(
                  totalSpent: dashProv.dashboard!.totalSpent,
                  monthlyBudget: dashProv.dashboard!.monthlyBudget,
                  currency: currency,
                ),
              ),
            const SizedBox(height: 20),

            // Section title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Category Budgets',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Budget list
            Expanded(
              child: budgetProv.loading && budgets.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : budgets.isEmpty
                  ? _EmptyState(onAdd: () => _showSetBudgetSheet())
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        await budgetProv.fetchBudgets();
                        await dashProv.fetchDashboard();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: budgets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _BudgetCard(
                          budget: budgets[i],
                          currency: currency,
                          onEdit: () =>
                              _showSetBudgetSheet(existing: budgets[i]),
                          onDelete: () => _deleteBudget(budgets[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<BudgetModel> _mergeBudgetsWithSpent(
    List<BudgetModel> budgets,
    Map<String, double> breakdown,
  ) {
    return budgets.map((b) {
      return b.copyWith(spent: breakdown[b.category] ?? 0);
    }).toList();
  }
}

//  Overall Budget Card ─

class _OverallBudgetCard extends StatelessWidget {
  final double totalSpent;
  final double monthlyBudget;
  final String currency;
  const _OverallBudgetCard({
    required this.totalSpent,
    required this.monthlyBudget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = monthlyBudget > 0
        ? (totalSpent / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;
    final isOver = totalSpent > monthlyBudget;
    final color = isOver ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Over Budget',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spent',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    CurrencyFormatter.format(totalSpent, currency: currency),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Budget',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    CurrencyFormatter.format(monthlyBudget, currency: currency),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//  Budget Card ─

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BudgetCard({
    required this.budget,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  String _emoji(String cat) {
    const map = {
      'Food': '🍔',
      'Transport': '🚗',
      'Shopping': '🛍️',
      'Bills': '💡',
      'Health': '💊',
      'Entertainment': '🎬',
      'Other': '📦',
    };
    return map[cat] ?? '📦';
  }

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.categoryColors[budget.category] ?? AppColors.primary;
    final ratio = budget.usageRatio.clamp(0.0, 1.0);
    final barColor = budget.isOverBudget ? AppColors.error : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: budget.isOverBudget
              ? AppColors.error.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _emoji(budget.category),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      budget.isOverBudget
                          ? 'Over by ${CurrencyFormatter.format(budget.spent - budget.limit, currency: currency)}'
                          : '${CurrencyFormatter.format(budget.remaining, currency: currency)} left',
                      style: TextStyle(
                        fontSize: 12,
                        color: budget.isOverBudget
                            ? AppColors.error
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 8),

          // Spent / Limit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyFormatter.format(budget.spent, currency: currency)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                'Limit: ${CurrencyFormatter.format(budget.limit, currency: currency)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//  Set Budget Bottom Sheet 

class _SetBudgetSheet extends StatefulWidget {
  final BudgetModel? existing;
  const _SetBudgetSheet({this.existing});

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitCtrl = TextEditingController();
  String _category = 'Food';

  bool get _isEditing => widget.existing != null;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'emoji': '🍔'},
    {'name': 'Transport', 'emoji': '🚗'},
    {'name': 'Shopping', 'emoji': '🛍️'},
    {'name': 'Bills', 'emoji': '💡'},
    {'name': 'Health', 'emoji': '💊'},
    {'name': 'Entertainment', 'emoji': '🎬'},
    {'name': 'Other', 'emoji': '📦'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _category = widget.existing!.category;
      _limitCtrl.text = widget.existing!.limit.toString();
    }
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<BudgetProvider>();
    final success = await prov.setBudget(
      category: _category,
      limit: double.parse(_limitCtrl.text.trim()),
    );
    if (success && mounted) {
      context.read<DashboardProvider>().fetchDashboard();
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Something went wrong'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<BudgetProvider>().loading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _isEditing ? 'Edit Budget' : 'Set Budget',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Category picker (disabled when editing)
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = cat['name'] == _category;
                final color =
                    AppColors.categoryColors[cat['name']] ?? AppColors.primary;
                final canSelect = !_isEditing;

                return GestureDetector(
                  onTap: canSelect
                      ? () => setState(() => _category = cat['name'])
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withOpacity(0.15)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? color : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat['emoji'],
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected ? color : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Limit amount
            const Text(
              'Monthly Limit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _limitCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: 'Rs ',
                prefixStyle: TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Limit is required';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                if (double.parse(v) <= 0) return 'Limit must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Submit
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Set Budget'),
            ),
          ],
        ),
      ),
    );
  }
}

//  Month Badge ─

class _MonthBadge extends StatelessWidget {
  final String month;
  const _MonthBadge({required this.month});

  @override
  Widget build(BuildContext context) {
    final parts = month.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return Container(
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
    );
  }
}

//  Empty State ─

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💰', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No budgets set',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set limits for each spending category',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Set Budget'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
          ),
        ],
      ),
    );
  }
}
