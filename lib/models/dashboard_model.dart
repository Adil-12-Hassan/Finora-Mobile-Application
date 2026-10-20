class DashboardModel {
  final double totalSpent;
  final double monthlyBudget;
  final double remaining;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;

  DashboardModel({
    required this.totalSpent,
    required this.monthlyBudget,
    required this.remaining,
    required this.transactionCount,
    required this.categoryBreakdown,
  });

  double get usageRatio => monthlyBudget > 0 ? totalSpent / monthlyBudget : 0;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    // Category breakdown map
    final breakdown = <String, double>{};
    final categoryData = json['categoryBreakdown'];
    if (categoryData is Map) {
      categoryData.forEach((category, amount) {
        breakdown[category.toString()] = _toDouble(amount);
      });
    } else if (categoryData is List) {
      for (final item in categoryData.whereType<Map>()) {
        final category = item['category'];
        if (category is String) {
          breakdown[category] = _toDouble(item['spent'] ?? item['total']);
        }
      }
    }

    return DashboardModel(
      totalSpent: _toDouble(json['totalSpent']),
      monthlyBudget: _toDouble(json['monthlyBudget']),
      remaining: _toDouble(json['remaining']),
      transactionCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      categoryBreakdown: breakdown,
    );
  }

  static double _toDouble(Object? value) =>
      value is num ? value.toDouble() : 0;
}
