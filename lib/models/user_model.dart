class UserModel {
  final String id;
  final String name;
  final String email;
  final String currency;
  final double monthlyBudget;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.monthlyBudget,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      currency: json['currency'] ?? 'PKR',
      monthlyBudget: (json['monthlyBudget'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'currency': currency,
    'monthlyBudget': monthlyBudget,
  };

  UserModel copyWith({
    String? name,
    String? email,
    String? currency,
    double? monthlyBudget,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}
