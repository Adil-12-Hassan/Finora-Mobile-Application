import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/expense_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense; // null = add, non-null = edit
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _category = 'Food';
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.expense != null;

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
      _amountCtrl.text = widget.expense!.amount.toString();
      _noteCtrl.text = widget.expense!.note ?? '';
      _category = widget.expense!.category;
      _date = widget.expense!.date;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
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
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.trim());
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final prov = context.read<ExpenseProvider>();

    bool success;

    if (_isEditing) {
      success = await prov.updateExpense(
        id: widget.expense!.id,
        amount: amount,
        category: _category,
        date: _date,
        note: note,
      );
    } else {
      success = await prov.addExpense(
        amount: amount,
        category: _category,
        date: _date,
        note: note,
      );
    }

    if (success && mounted) {
      // Refresh dashboard cache
      context.read<DashboardProvider>().fetchDashboard();
      context.pop();
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
    final loading = context.watch<ExpenseProvider>().loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    prefixText: 'Rs ',
                    prefixStyle: TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount is required';
                    if (double.tryParse(v) == null)
                      return 'Enter a valid number';
                    if (double.parse(v) <= 0)
                      return 'Amount must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Category
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((cat) {
                    final selected = cat['name'] == _category;
                    final color =
                        AppColors.categoryColors[cat['name']] ??
                        AppColors.primary;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat['name']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
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
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['name'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? color
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Date
                const Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.format(_date),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Note
                const Text(
                  'Note (optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'What was this expense for?',
                  ),
                ),
                const SizedBox(height: 40),

                // Submit button
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
                      : Text(_isEditing ? 'Save Changes' : 'Add Expense'),
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
