import 'budget_model.dart';

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class DashboardModel {
  final int transactionCount;
  final double totalSpent;
  final double monthlyBudget;
  final double remaining;
  final Map<String, double> categoryBreakdown;
  final List<BudgetModel> budgets;
  final List<DailySpend> dailySpend;

  DashboardModel({
    required this.transactionCount,
    required this.totalSpent,
    required this.monthlyBudget,
    required this.remaining,
    required this.categoryBreakdown,
    required this.budgets,
    required this.dailySpend, // ← and this
  });

  double get usageRatio => monthlyBudget > 0 ? totalSpent / monthlyBudget : 0;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final Map<String, double> breakdown = {};
    final charts = json['charts'] is Map
        ? Map<String, dynamic>.from(json['charts'] as Map)
        : <String, dynamic>{};
    final raw = json['categoryBreakdown'] ?? charts['category'];
    if (raw is Map) {
      raw.forEach((k, v) {
        breakdown[k.toString()] = _toDouble(v);
      });
    } else if (raw is List) {
      for (final item in raw) {
        final key = item['category'] ?? item['_id'] ?? '';
        final value = _toDouble(
          item['spent'] ?? item['amount'] ?? item['total'],
        );
        if (key.isNotEmpty) breakdown[key] = value;
      }
    }

    final budgets = (json['budgets'] as List<dynamic>? ?? [])
        .map((b) => BudgetModel.fromJson(b))
        .toList();

    final dailyRaw = json['dailySpend'] ?? charts['daily'];
    final daily = (dailyRaw as List<dynamic>? ?? [])
        .map(
          (d) => DailySpend.fromJson(
            Map<String, dynamic>.from(d as Map),
            month: json['month']?.toString(),
          ),
        )
        .toList();

    return DashboardModel(
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      monthlyBudget: (json['monthlyBudget'] ?? 0).toDouble(),
      remaining: (json['remaining'] ?? 0).toDouble(),
        transactionCount:
          (json['transactionCount'] ?? json['totalCount'] ?? 0) as int,
      categoryBreakdown: breakdown,
      budgets: budgets,
      dailySpend: daily,
    );
  }
}

class DailySpend {
  final String date;
  final double amount;

  DailySpend({required this.date, required this.amount});

  factory DailySpend.fromJson(
    Map<String, dynamic> json, {
    String? month,
  }) {
    final day = json['day'];
    final date = json['date']?.toString() ??
        (month != null && day is num
            ? '$month-${day.toInt().toString().padLeft(2, '0')}'
            : '');

    return DailySpend(
      date: date,
      amount: _toDouble(json['amount'] ?? json['total']),
    );
  }
}
