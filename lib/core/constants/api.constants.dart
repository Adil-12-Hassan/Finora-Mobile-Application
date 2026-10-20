class ApiConstants {
  static const String baseUrl = 'https://finoraserver.vercel.app';
  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  // Expenses
  static const String expenses = '/api/expenses';
  // Dashboard
  static const String dashboard = '/api/dashboard/summary';
  // Reports
  static const String reports = '/api/dashboard/reports';
  // Budgets
  static const String budgets = '/api/budgets';
  // Settings
  static const String updateProfile = '/api/auth/me';
  static const String changePassword = '/api/auth/change-password';
}