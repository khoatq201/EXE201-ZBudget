import 'package:intl/intl.dart';

/// Utility class for standardized currency formatting across the app
///
/// This ensures consistency when displaying monetary amounts in the UI,
/// especially for financial transactions (expenses, income, budgets, reports)
///
/// **Supported Currencies:**
/// - VND (Vietnamese Dong) - Default
/// - USD (US Dollar)
/// - EUR (Euro)
///
/// **Usage:**
/// ```dart
/// // Format VND (default)
/// CurrencyFormatter.format(1000000); // "1.000.000 ₫"
/// CurrencyFormatter.formatVND(1000000); // "1.000.000 ₫"
///
/// // Format USD
/// CurrencyFormatter.formatUSD(1000.50); // "$1,000.50"
///
/// // Format with custom currency
/// CurrencyFormatter.formatWithCurrency(1000000, 'VND'); // "1.000.000 ₫"
///
/// // Compact format for large numbers
/// CurrencyFormatter.formatCompact(1500000); // "1.5M ₫"
///
/// // Format for API (remove symbols)
/// CurrencyFormatter.toApiFormat(1000000); // 1000000.0
/// ```
class CurrencyFormatter {
  CurrencyFormatter._(); // Private constructor to prevent instantiation

  // Currency symbols
  static const String vndSymbol = '₫';
  static const String usdSymbol = '\$';
  static const String eurSymbol = '€';

  // Number formatters for different currencies
  static final NumberFormat _vndFormatter = NumberFormat('#,##0', 'vi_VN');
  static final NumberFormat _usdFormatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _eurFormatter = NumberFormat('#,##0.00', 'de_DE');

  /// Formats amount in VND (default currency)
  ///
  /// Example: 1000000 → "1.000.000 ₫"
  static String format(double amount) {
    return formatVND(amount);
  }

  /// Formats amount in Vietnamese Dong (VND)
  ///
  /// - Uses dot (.) as thousand separator
  /// - No decimal places (VND doesn't use decimals)
  /// - Symbol: ₫ (placed after amount)
  ///
  /// Example: 1000000 → "1.000.000 ₫"
  static String formatVND(double amount) {
    // VND doesn't use decimal places
    final formattedAmount = _vndFormatter.format(amount.round());
    return '$formattedAmount $vndSymbol';
  }

  /// Formats amount in US Dollars (USD)
  ///
  /// - Uses comma (,) as thousand separator
  /// - Always shows 2 decimal places
  /// - Symbol: $ (placed before amount)
  ///
  /// Example: 1000.50 → "$1,000.50"
  static String formatUSD(double amount) {
    final formattedAmount = _usdFormatter.format(amount);
    return '$usdSymbol$formattedAmount';
  }

  /// Formats amount in Euros (EUR)
  ///
  /// - Uses dot (.) as thousand separator
  /// - Uses comma (,) as decimal separator
  /// - Always shows 2 decimal places
  /// - Symbol: € (placed after amount)
  ///
  /// Example: 1000.50 → "1.000,50 €"
  static String formatEUR(double amount) {
    final formattedAmount = _eurFormatter.format(amount);
    return '$formattedAmount $eurSymbol';
  }

  /// Formats amount with specified currency code
  ///
  /// Supported codes: 'VND', 'USD', 'EUR'
  /// Defaults to VND for unknown currencies
  ///
  /// Example: formatWithCurrency(1000000, 'VND') → "1.000.000 ₫"
  static String formatWithCurrency(double amount, String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return formatUSD(amount);
      case 'EUR':
        return formatEUR(amount);
      case 'VND':
      default:
        return formatVND(amount);
    }
  }

  /// Formats amount in compact form for large numbers
  ///
  /// - K = Thousand (1,000)
  /// - M = Million (1,000,000)
  /// - B = Billion (1,000,000,000)
  ///
  /// Examples:
  /// - 1500000 → "1.5M ₫"
  /// - 750000 → "750K ₫"
  /// - 1500 → "1.500 ₫"
  static String formatCompact(double amount, [String currencyCode = 'VND']) {
    final absAmount = amount.abs();
    final isNegative = amount < 0;
    final prefix = isNegative ? '-' : '';

    String compactValue;
    if (absAmount >= 1000000000) {
      // Billions
      compactValue = '${(absAmount / 1000000000).toStringAsFixed(1)}B';
    } else if (absAmount >= 1000000) {
      // Millions
      compactValue = '${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 10000) {
      // Thousands (only for amounts >= 10K to avoid showing small amounts as "1.5K")
      compactValue = '${(absAmount / 1000).toStringAsFixed(0)}K';
    } else {
      // Show full amount for smaller numbers
      return formatWithCurrency(amount, currencyCode);
    }

    // Add currency symbol
    final symbol = _getCurrencySymbol(currencyCode);
    return '$prefix$compactValue $symbol';
  }

  /// Formats amount without currency symbol (for input fields)
  ///
  /// Uses thousand separators but no currency symbol
  ///
  /// Example: 1000000 → "1.000.000"
  static String formatWithoutSymbol(
    double amount, [
    String currencyCode = 'VND',
  ]) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
      case 'EUR':
        return _usdFormatter.format(amount);
      case 'VND':
      default:
        return _vndFormatter.format(amount.round());
    }
  }

  /// Parses formatted currency string back to number
  ///
  /// Removes all non-numeric characters except decimal point
  ///
  /// Examples:
  /// - "1.000.000 ₫" → 1000000.0
  /// - "$1,000.50" → 1000.50
  /// - "1.000,50 €" → 1000.50
  static double parse(String formattedAmount) {
    // Remove currency symbols and spaces
    String cleaned = formattedAmount
        .replaceAll(vndSymbol, '')
        .replaceAll(usdSymbol, '')
        .replaceAll(eurSymbol, '')
        .replaceAll(' ', '')
        .trim();

    // Handle European format (comma as decimal separator)
    if (cleaned.contains(',') && !cleaned.contains('.')) {
      // European format: 1.000,50 → 1000.50
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains('.') && cleaned.contains(',')) {
      // Mixed format: determine which is decimal separator
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');

      if (lastComma > lastDot) {
        // Comma is decimal separator: 1.000,50
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Dot is decimal separator: 1,000.50
        cleaned = cleaned.replaceAll(',', '');
      }
    } else {
      // Only dots or only commas
      if (cleaned.contains(',')) {
        // Could be thousand separator or decimal
        final parts = cleaned.split(',');
        if (parts.length == 2 && parts[1].length <= 2) {
          // Likely decimal: 1000,50
          cleaned = cleaned.replaceAll(',', '.');
        } else {
          // Thousand separator: 1,000,000
          cleaned = cleaned.replaceAll(',', '');
        }
      }
      // If only dots, assume thousand separators: 65.000 or 1.000.000
      // Need >= 2 parts (at least one dot) to be thousand separator
      if (cleaned.contains('.')) {
        final parts = cleaned.split('.');
        // Check if this looks like a thousand separator pattern
        // VND format uses dots for thousands: 65.000, 1.000.000
        // Each part after first should be exactly 3 digits for thousands
        bool isThousandSeparator = parts.length >= 2;
        if (isThousandSeparator && parts.length == 2) {
          // For exactly one dot, verify the pattern (e.g., 65.000)
          // Should have 3 digits after the dot for thousand separator
          isThousandSeparator = parts[1].length == 3;
        }
        if (isThousandSeparator) {
          cleaned = cleaned.replaceAll('.', '');
        }
      }
    }

    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Converts amount to API format (plain number)
  ///
  /// Returns the raw number value for sending to backend
  ///
  /// Example: 1000000 → 1000000.0
  static double toApiFormat(double amount) {
    return amount;
  }

  /// Parses amount from API response
  ///
  /// Handles both number and string responses
  ///
  /// Example: "1000000" or 1000000 → 1000000.0
  static double fromApiFormat(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  /// Formats amount with color coding for positive/negative values
  ///
  /// Returns a Map with 'text' and 'isPositive' keys
  /// Useful for showing income (green) vs expense (red)
  ///
  /// Example:
  /// - formatWithSign(1000000) → {'text': '+1.000.000 ₫', 'isPositive': true}
  /// - formatWithSign(-500000) → {'text': '-500.000 ₫', 'isPositive': false}
  static Map<String, dynamic> formatWithSign(
    double amount, [
    String currencyCode = 'VND',
  ]) {
    final isPositive = amount >= 0;
    final sign = isPositive ? '+' : '';
    final formatted = formatWithCurrency(amount.abs(), currencyCode);

    return {'text': '$sign$formatted', 'isPositive': isPositive};
  }

  /// Formats amount as income (positive, green)
  ///
  /// Always shows with + sign
  ///
  /// Example: 1000000 → "+1.000.000 ₫"
  static String formatIncome(double amount, [String currencyCode = 'VND']) {
    final formatted = formatWithCurrency(amount, currencyCode);
    return '+$formatted';
  }

  /// Formats amount as expense (negative, red)
  ///
  /// Always shows with - sign
  ///
  /// Example: 500000 → "-500.000 ₫"
  static String formatExpense(double amount, [String currencyCode = 'VND']) {
    final formatted = formatWithCurrency(amount, currencyCode);
    return '-$formatted';
  }

  /// Calculates percentage and formats it
  ///
  /// Example: formatPercentage(250000, 1000000) → "25%"
  static String formatPercentage(double part, double total) {
    if (total == 0) return '0%';
    final percentage = (part / total * 100).round();
    return '$percentage%';
  }

  /// Formats a ratio between two amounts
  ///
  /// Example: formatRatio(500000, 1000000) → "500.000 / 1.000.000 ₫"
  static String formatRatio(
    double amount1,
    double amount2, [
    String currencyCode = 'VND',
  ]) {
    final formatted1 = formatWithoutSymbol(amount1, currencyCode);
    final formatted2 = formatWithoutSymbol(amount2, currencyCode);
    final symbol = _getCurrencySymbol(currencyCode);
    return '$formatted1 / $formatted2 $symbol';
  }

  /// Formats amount for budget display (spent / total)
  ///
  /// Example: formatBudget(750000, 1000000) → "750.000 / 1.000.000 ₫ (75%)"
  static String formatBudget(
    double spent,
    double total, [
    String currencyCode = 'VND',
  ]) {
    final ratio = formatRatio(spent, total, currencyCode);
    final percentage = formatPercentage(spent, total);
    return '$ratio ($percentage)';
  }

  /// Validates if a string can be parsed as currency
  ///
  /// Returns true if the string represents a valid currency amount
  static bool isValid(String value) {
    try {
      final parsed = parse(value);
      return parsed >= 0;
    } catch (e) {
      return false;
    }
  }

  /// Gets currency symbol for given currency code
  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return usdSymbol;
      case 'EUR':
        return eurSymbol;
      case 'VND':
      default:
        return vndSymbol;
    }
  }

  /// Converts between currencies (requires exchange rates)
  ///
  /// Note: This is a placeholder. For production, integrate with a real
  /// exchange rate API or service
  ///
  /// Example: convert(1000000, 'VND', 'USD', 0.000041) → 41.0
  static double convert(
    double amount,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
  ) {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return amount;
    }
    return amount * exchangeRate;
  }

  /// Formats currency input for text fields
  ///
  /// Returns formatted string as user types, with cursor position
  /// Useful for TextFormField formatters
  ///
  /// Example: formatInput("1000000") → "1.000.000"
  static String formatInput(String value, [String currencyCode = 'VND']) {
    // Remove all non-numeric characters
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) return '';

    final number = double.tryParse(cleaned);
    if (number == null) return '';

    return formatWithoutSymbol(number, currencyCode);
  }

  /// Checks if amount exceeds budget limit
  ///
  /// Returns true if amount > limit
  static bool isOverBudget(double amount, double limit) {
    return amount > limit;
  }

  /// Calculates remaining budget
  ///
  /// Returns limit - spent (can be negative if over budget)
  static double calculateRemaining(double spent, double limit) {
    return limit - spent;
  }

  /// Formats remaining budget with color coding
  ///
  /// Returns Map with 'text' and 'isOverBudget' keys
  static Map<String, dynamic> formatRemaining(
    double spent,
    double limit, [
    String currencyCode = 'VND',
  ]) {
    final remaining = calculateRemaining(spent, limit);
    final isOver = remaining < 0;

    return {
      'text': formatWithCurrency(remaining.abs(), currencyCode),
      'isOverBudget': isOver,
    };
  }
}

/// Extension methods for double to make currency formatting easier
extension CurrencyExtension on double {
  /// Format this amount as VND
  ///
  /// Example: 1000000.0.toVND() → "1.000.000 ₫"
  String toVND() => CurrencyFormatter.formatVND(this);

  /// Format this amount as USD
  ///
  /// Example: 1000.50.toUSD() → "$1,000.50"
  String toUSD() => CurrencyFormatter.formatUSD(this);

  /// Format this amount as EUR
  ///
  /// Example: 1000.50.toEUR() → "1.000,50 €"
  String toEUR() => CurrencyFormatter.formatEUR(this);

  /// Format this amount in compact form
  ///
  /// Example: 1500000.0.toCompact() → "1.5M ₫"
  String toCompact([String currency = 'VND']) =>
      CurrencyFormatter.formatCompact(this, currency);

  /// Format this amount with specified currency
  ///
  /// Example: 1000000.0.toCurrency('VND') → "1.000.000 ₫"
  String toCurrency(String currencyCode) =>
      CurrencyFormatter.formatWithCurrency(this, currencyCode);
}
