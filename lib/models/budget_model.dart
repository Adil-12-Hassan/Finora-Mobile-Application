class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double limit;
  final String month; // "2026-10" format - matches Redis key
  double spent; // filled from dashboard data, not stored in DB

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.limit,
    required this.month,
    this.spent = 0,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      category: json['category'] ?? 'Other',
      limit: (json['limit'] ?? 0).toDouble(),
      month: json['month'] ?? '',
      spent: (json['spent'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'limit': limit,
    'month': month,
  };

  // How much of the budget is used - 0.0 to 1.0+
  double get usageRatio => limit > 0 ? spent / limit : 0;

  // Remaining amount
  double get remaining => limit - spent;

  // Is over budget
  bool get isOverBudget => spent > limit;

  BudgetModel copyWith({double? limit, double? spent}) {
    return BudgetModel(
      id: id,
      userId: userId,
      category: category,
      limit: limit ?? this.limit,
      month: month,
      spent: spent ?? this.spent,
    );
  }
}
