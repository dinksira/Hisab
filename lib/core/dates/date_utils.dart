import 'package:intl/intl.dart';

/// Date utility functions for financial boundaries, week starts, and date-only normalization.
class AppDateUtils {
  AppDateUtils._();

  /// Normalize to date-only (00:00:00 local) to avoid timestamp drift in financial dates
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Format as YYYY-MM-DD for PostgreSQL and API payloads
  static String toIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parse YYYY-MM-DD safely into date-only
  static DateTime parseIsoDate(String isoString) {
    final parts = isoString.split('-');
    if (parts.length >= 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2].substring(0, 2)),
      );
    }
    return dateOnly(DateTime.parse(isoString));
  }

  /// Returns Start and End boundary for a monthly budget or period
  static ({DateTime start, DateTime end}) getMonthBoundaries(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final nextMonthFirst = DateTime(date.year, date.month + 1, 1);
    final end = nextMonthFirst.subtract(const Duration(days: 1));
    return (start: start, end: end);
  }

  /// Returns Start and End boundary for a weekly budget given week start day (1 = Monday, 7 = Sunday)
  static ({DateTime start, DateTime end}) getWeekBoundaries(DateTime date, {int weekStartsOn = 1}) {
    final clean = dateOnly(date);
    final diff = (clean.weekday - weekStartsOn + 7) % 7;
    final start = clean.subtract(Duration(days: diff));
    final end = start.add(const Duration(days: 6));
    return (start: start, end: end);
  }

  /// Returns Start and End boundary for a yearly budget
  static ({DateTime start, DateTime end}) getYearBoundaries(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    final end = DateTime(date.year, 12, 31);
    return (start: start, end: end);
  }

  /// Display formatting
  static String formatShort(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  static String formatMonthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);
  static String formatDayMonth(DateTime date) => DateFormat('d MMM').format(date);
  static String formatRelative(DateTime date) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(date);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return formatShort(date);
  }
}
