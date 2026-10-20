import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _scrollCtrl = ScrollController();

  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Entertainment',
    'Other',
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().fetchExpenses(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ExpenseProvider>().loadMore();
    }
  }

  void _onCategoryTap(String category) {
    setState(() => _selectedCategory = category);
    final prov = context.read<ExpenseProvider>();
    prov.setCategory(category == 'All' ? null : category);
  }

  Future<void> _deleteExpense(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Expense',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this expense?',
          style: TextStyle(color: AppColors.textSecondary),
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
      final success = await context.read<ExpenseProvider>().deleteExpense(id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete expense'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final currency = context.watch<AuthProvider>().user?.currency ?? 'PKR';

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
                    'Transactions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Month selector
                  _MonthSelector(
                    month: expProv.month,
                    onChanged: (m) => expProv.setMonth(m),
                  ),
                ],
              ),
            ),

            // Category filter chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => _onCategoryTap(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: expProv.loading && expProv.expenses.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : expProv.expenses.isEmpty
                  ? _EmptyState(
                      category: _selectedCategory,
                      onAdd: () => context.push('/add-expense'),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () => expProv.fetchExpenses(refresh: true),
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount:
                            expProv.expenses.length + (expProv.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          // Load more indicator
                          if (i == expProv.expenses.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final expense = expProv.expenses[i];
                          return _ExpenseCard(
                            expense: expense,
                            currency: currency,
                            onEdit: () =>
                                context.push('/add-expense', extra: expense),
                            onDelete: () => _deleteExpense(expense.id),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-expense'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Month Selector ────────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final String month;
  final Function(String) onChanged;
  const _MonthSelector({required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Parse "2026-10" into DateTime
    final parts = month.split('-');
    var date = DateTime(int.parse(parts[0]), int.parse(parts[1]));

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
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.surface,
                    onSurface: AppColors.textPrimary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              onChanged(DateFormatter.toMonthKey(picked));
            }
          },
          child: Container(
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

// ─── Expense Card ──────────────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExpenseCard({
    required this.expense,
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
        AppColors.categoryColors[expense.category] ?? AppColors.primary;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => false, // handled by onDelete
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.error,
          size: 24,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Emoji circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _emoji(expense.category),
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
                    expense.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    expense.note?.isNotEmpty == true
                        ? expense.note!
                        : DateFormatter.format(expense.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Amount + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- ${CurrencyFormatter.format(expense.amount, currency: currency)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String category;
  final VoidCallback onAdd;
  const _EmptyState({required this.category, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💸', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            category == 'All' ? 'No transactions yet' : 'No $category expenses',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to log an expense',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
          ),
        ],
      ),
    );
  }
}
