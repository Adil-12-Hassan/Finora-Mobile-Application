import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  static String formatShort(DateTime date) => DateFormat('MMM dd').format(date);

  static String formatMonth(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  // Returns "2026-10" format - matches your Redis key pattern
  static String toMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
