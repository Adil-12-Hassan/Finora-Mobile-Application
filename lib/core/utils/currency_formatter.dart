import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'PKR'}) {
    final formatter = NumberFormat.currency(
      symbol: _getSymbol(currency),
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String _getSymbol(String currency) {
    const symbols = {'PKR': 'Rs ', 'USD': '\$', 'EUR': '€', 'GBP': '£'};
    return symbols[currency] ?? '$currency ';
  }
}
