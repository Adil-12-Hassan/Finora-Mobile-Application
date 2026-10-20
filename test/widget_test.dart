// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/app.dart';
import 'package:finora/models/dashboard_model.dart';

void main() {
  test('Dashboard summary parses the backend response format', () {
    final dashboard = DashboardModel.fromJson({
      'totalSpent': 125.5,
      'monthlyBudget': 500,
      'remaining': 374.5,
      'totalCount': 3,
      'categoryBreakdown': [
        {'category': 'Food', 'spent': 100},
        {'category': 'Transport', 'spent': 25.5},
      ],
      'month': '2026-10',
      'charts': {
        'daily': [
          {'day': 1, 'total': 15.5},
          {'day': 2, 'total': 0},
        ],
      },
    });

    expect(dashboard.totalSpent, 125.5);
    expect(dashboard.transactionCount, 3);
    expect(dashboard.categoryBreakdown, {
      'Food': 100,
      'Transport': 25.5,
    });
    expect(dashboard.dailySpend.first.date, '2026-10-01');
    expect(dashboard.dailySpend.first.amount, 15.5);
    expect(dashboard.dailySpend.last.amount, 0);
  });

  testWidgets('Splash screen displays Finora branding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('Finora'), findsOneWidget);
  });
}
