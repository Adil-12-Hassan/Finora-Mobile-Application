import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/transactions/add_expense_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/budgets/budgets_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/widgets/finora_logo.dart';

class FinoraApp extends StatefulWidget {
  const FinoraApp({super.key});

  @override
  State<FinoraApp> createState() => _FinoraAppState();
}

class _FinoraAppState extends State<FinoraApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _router = GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        final isAuth = status == AuthStatus.authenticated;
        final isUnknown = status == AuthStatus.unknown;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // Still checking session
        if (isUnknown) return '/splash';

        // Not logged in and not on auth screen
        if (!isAuth && !isAuthRoute) return '/login';

        // Logged in but on auth screen
        if (isAuth && isAuthRoute) return '/dashboard';

        return null;
      },
      routes: [
        // Splash - session check
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

        // Auth routes
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

        // Main app - shell with bottom nav
        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (_, __) => const TransactionsScreen(),
            ),
            GoRoute(
              path: '/reports',
              builder: (_, __) => const ReportsScreen(),
            ),
            GoRoute(
              path: '/budgets',
              builder: (_, __) => const BudgetsScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
            ),
          ],
        ),

        // Add expense - full screen modal, outside shell
        GoRoute(
          path: '/add-expense',
          builder: (_, state) {
            final expense = state.extra; // pass existing expense for editing
            return AddExpenseScreen(expense: expense as dynamic);
          },
        ),
      ],
    );

    // Check session on startup
    authProvider.checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

// Splash screen - shown while checking session
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FinoraLogo(size: 96),
            SizedBox(height: 24),
            Text(
              'Finora',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C6EF5),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF7C6EF5)),
          ],
        ),
      ),
    );
  }
}
