/// Utility class for standardized date formatting across the app
///
/// This ensures consistency when communicating with the backend API,
/// especially for financial transactions (expenses, income, budgets, reports)
///
/// **Why YYYY-MM-DD format?**
/// - Avoids timezone conversion issues between client and server
/// - Backend stores dates in MongoDB which interprets YYYY-MM-DD as local date
/// - ISO 8601 with time (e.g., 2025-10-04T21:30:00.000) causes timezone shifts
/// - Example: User selects Oct 4 at 9:30 PM (21:30 local time)
///   - If sent as ISO with time: 2025-10-04T21:30:00 → Backend parses as UTC → Saved as Oct 3
///   - If sent as YYYY-MM-DD: 2025-10-04 → Backend interprets correctly as Oct 4
///
/// **Usage:**
/// ```dart
/// // When sending date to API
/// body['date'] = DateFormatter.toApiFormat(selectedDate);
///
/// // When parsing date from API response
/// final date = DateFormatter.parseApiDate(json['date']);
///
/// // Display formatting
/// DateFormatter.toDisplayFormat(date); // "4 Thg 10, 2025"
/// DateFormatter.toShortDisplay(date);  // "04/10/2025"
/// ```
class DateFormatter {
  DateFormatter._(); // Private constructor to prevent instantiation

  /// Converts a DateTime to API format (YYYY-MM-DD)
  ///
  /// This format should be used for ALL date fields sent to the backend API:
  /// - Expense creation/update
  /// - Income creation/update
  /// - Budget period dates (startDate, endDate)
  /// - Group expense dates
  /// - Report date filters
  ///
  /// Example: DateTime(2025, 10, 4) → "2025-10-04"
  static String toApiFormat(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Converts a DateTime to API format with null safety
  /// Returns null if input is null
  static String? toApiFormatNullable(DateTime? date) {
    return date != null ? toApiFormat(date) : null;
  }

  /// Parses a date string from API response
  ///
  /// Handles multiple formats:
  /// - ISO 8601 with time: "2025-10-04T14:30:00.000Z"
  /// - ISO 8601 date only: "2025-10-04"
  /// - MongoDB date format: "2025-10-04T14:30:00.000Z"
  ///
  /// Always returns DateTime in local timezone
  static DateTime parseApiDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      throw FormatException('Invalid date format: $dateString');
    }
  }

  /// Parses a date string with null safety
  /// Returns null if input is null or empty
  static DateTime? parseApiDateNullable(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    return parseApiDate(dateString);
  }

  /// Formats date for display in Vietnamese locale
  /// Example: "4 Thg 10, 2025"
  static String toDisplayFormat(DateTime date) {
    const months = [
      'Thg 1', 'Thg 2', 'Thg 3', 'Thg 4', 'Thg 5', 'Thg 6',
      'Thg 7', 'Thg 8', 'Thg 9', 'Thg 10', 'Thg 11', 'Thg 12'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  /// Formats date for short display
  /// Example: "04/10/2025" (DD/MM/YYYY)
  static String toShortDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formats date with time for display
  /// Example: "04/10/2025 21:30"
  static String toDisplayWithTime(DateTime date) {
    return '${toShortDisplay(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Formats date for month/year display
  /// Example: "Thg 10, 2025"
  static String toMonthYearDisplay(DateTime date) {
    const months = [
      'Thg 1', 'Thg 2', 'Thg 3', 'Thg 4', 'Thg 5', 'Thg 6',
      'Thg 7', 'Thg 8', 'Thg 9', 'Thg 10', 'Thg 11', 'Thg 12'
    ];
    return '${months[date.month - 1]}, ${date.year}';
  }

  /// Returns the start of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns the end of day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Returns the first day of the month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Returns the last day of the month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Returns the first day of the year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Returns the last day of the year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// Checks if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Checks if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Checks if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Returns relative date display (e.g., "Hôm nay", "Hôm qua", or actual date)
  static String toRelativeDisplay(DateTime date) {
    if (isToday(date)) return 'Hôm nay';
    if (isYesterday(date)) return 'Hôm qua';
    return toShortDisplay(date);
  }

  /// Formats date range for display
  /// Example: "1 - 31 Thg 10, 2025"
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      // Same month
      const months = [
        'Thg 1', 'Thg 2', 'Thg 3', 'Thg 4', 'Thg 5', 'Thg 6',
        'Thg 7', 'Thg 8', 'Thg 9', 'Thg 10', 'Thg 11', 'Thg 12'
      ];
      return '${start.day} - ${end.day} ${months[start.month - 1]}, ${start.year}';
    } else {
      // Different months or years
      return '${toShortDisplay(start)} - ${toShortDisplay(end)}';
    }
  }

  /// Gets the number of days in a month
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Calculates the difference in days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
}
