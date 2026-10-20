class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      date: DateTime.parse(json['date']),
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
  };

  ExpenseModel copyWith({
    double? amount,
    String? category,
    DateTime? date,
    String? note,
  }) {
    return ExpenseModel(
      id: id,
      userId: userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}
