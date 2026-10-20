class ApiConstants {
  static const String baseUrl = 'https://finoraserver.vercel.app/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Expenses
  static const String expenses = '/expenses';

  // Dashboard
  static const String dashboard = '/dashboard/summary';

  // Reports
  static const String reports = '/dashboard/reports';

  // Budgets
  static const String budgets = '/budgets';

  // Settings (User)
  static const String updateProfile = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Timeouts
  static const int connectTimeout = 10000; // 10s
  static const int receiveTimeout = 15000; // 15s
}
