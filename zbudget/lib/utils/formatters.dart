/// Central export file for all formatters
///
/// This file provides a single import point for all formatting utilities
/// used across the ZBudget application.
///
/// **Usage:**
/// ```dart
/// import '../utils/formatters.dart';
///
/// // Date formatting
/// final date = DateFormatter.toApiFormat(DateTime.now());
/// final display = DateFormatter.toDisplayFormat(DateTime.now());
///
/// // Currency formatting
/// final amount = CurrencyFormatter.format(1000000);
/// final compact = 1500000.0.toCompact();
/// ```
///
/// **Available Formatters:**
/// - `DateFormatter` - Standardized date formatting (YYYY-MM-DD for API)
/// - `CurrencyFormatter` - Standardized currency formatting (VND, USD, EUR)
/// - `CurrencyInputFormatter` - TextInputFormatter for currency input fields
///
/// For detailed documentation, see:
/// - DATE_FORMATTING_GUIDE.md
/// - CURRENCY_FORMATTING_GUIDE.md
library;

export 'date_formatter.dart';
export 'currency_formatter.dart';
export 'currency_input_formatter.dart';
