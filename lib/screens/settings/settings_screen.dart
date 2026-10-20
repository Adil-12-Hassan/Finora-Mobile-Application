import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/dashboard_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  //  Profile Edit 
  void _showEditProfileSheet() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final formKey = GlobalKey<FormState>();
    String currency = user.currency;

    final currencies = ['PKR', 'USD', 'EUR', 'GBP'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            final loading = context.read<AuthProvider>().loading;

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 24),
              child: Form(
                key: formKey,
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
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Your name',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: AppColors.textMuted,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Name is required';
                        if (v.length < 2) return 'Name too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Currency
                    const Text(
                      'Currency',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currencies.map((c) {
                        final selected = c == currency;
                        return GestureDetector(
                          onTap: () => setSheetState(() => currency = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withOpacity(0.15)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Save
                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final success = await context
                                  .read<AuthProvider>()
                                  .updateProfile(
                                    name: nameCtrl.text.trim(),
                                    currency: currency,
                                  );
                              if (success && ctx.mounted) {
                                Navigator.pop(ctx);
                                _showSnack('Profile updated');
                              }
                            },
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //  Monthly Budget Edit ──
  void _showEditBudgetSheet() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final limitCtrl = TextEditingController(
      text: user.monthlyBudget.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            final loading = context.read<AuthProvider>().loading;

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set your total spending limit for the month.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: limitCtrl,
                      autofocus: true,
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
                        if (v == null || v.isEmpty) return 'Budget is required';
                        if (double.tryParse(v) == null)
                          return 'Enter a valid number';
                        if (double.parse(v) <= 0)
                          return 'Must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final success = await context
                                  .read<AuthProvider>()
                                  .updateProfile(
                                    monthlyBudget: double.parse(
                                      limitCtrl.text.trim(),
                                    ),
                                  );
                              if (success && ctx.mounted) {
                                context
                                    .read<DashboardProvider>()
                                    .fetchDashboard();
                                Navigator.pop(ctx);
                                _showSnack('Budget updated');
                              }
                            },
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Budget'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //  Change Password 
  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure1 = true;
    bool obscure2 = true;
    bool obscure3 = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            final loading = context.read<AuthProvider>().loading;

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Current password
                    TextFormField(
                      controller: currentCtrl,
                      obscureText: obscure1,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.textMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure1
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              setSheetState(() => obscure1 = !obscure1),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // New password
                    TextFormField(
                      controller: newCtrl,
                      obscureText: obscure2,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.textMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure2
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              setSheetState(() => obscure2 = !obscure2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Confirm password
                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: obscure3,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.textMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure3
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              setSheetState(() => obscure3 = !obscure3),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != newCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final success = await context
                                  .read<AuthProvider>()
                                  .changePassword(
                                    currentPassword: currentCtrl.text.trim(),
                                    newPassword: newCtrl.text.trim(),
                                  );
                              if (success && ctx.mounted) {
                                Navigator.pop(ctx);
                                _showSnack('Password changed');
                              } else if (ctx.mounted) {
                                _showSnack(
                                  context.read<AuthProvider>().error ??
                                      'Failed',
                                  isError: true,
                                );
                              }
                            },
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Change Password'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //  Logout ──
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
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
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      // Clear all provider states
      if (mounted) {
        context.read<ExpenseProvider>().fetchExpenses(refresh: true);
        context.read<BudgetProvider>().fetchBudgets();
        context.read<DashboardProvider>().fetchDashboard();
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currency = user?.currency ?? 'PKR';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Profile card
              _ProfileCard(
                name: user?.name ?? '',
                email: user?.email ?? '',
                onEdit: _showEditProfileSheet,
              ),
              const SizedBox(height: 24),

              // Account section
              _SectionLabel(label: 'Account'),
              const SizedBox(height: 10),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: Icons.account_circle_outlined,
                    label: 'Edit Profile',
                    subtitle: user?.name ?? '',
                    onTap: _showEditProfileSheet,
                  ),
                  _SettingsItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Monthly Budget',
                    subtitle: CurrencyFormatter.format(
                      user?.monthlyBudget ?? 0,
                      currency: currency,
                    ),
                    onTap: _showEditBudgetSheet,
                  ),
                  _SettingsItem(
                    icon: Icons.monetization_on_outlined,
                    label: 'Currency',
                    subtitle: currency,
                    onTap: _showEditProfileSheet,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Security section
              _SectionLabel(label: 'Security'),
              const SizedBox(height: 10),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: _showChangePasswordSheet,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // App section
              _SectionLabel(label: 'App'),
              const SizedBox(height: 10),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: Icons.info_outline,
                    label: 'Version',
                    subtitle: '1.0.0',
                    onTap: null,
                    showArrow: false,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.error,
                    size: 18,
                  ),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

//  Profile Card 

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEdit;
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//  Settings Group 

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 0,
                  color: AppColors.border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

//  Settings Item ─

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showArrow;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            if (showArrow && onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

//  Section Label ─

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}
