import 'package:flutter/services.dart';
import 'currency_formatter.dart';

/// TextInputFormatter for currency input fields
///
/// Automatically formats numbers with thousand separators as user types
/// Supports VND format: 1.000.000
///
/// **Usage:**
/// ```dart
/// TextFormField(
///   keyboardType: TextInputType.number,
///   inputFormatters: [
///     FilteringTextInputFormatter.digitsOnly,
///     CurrencyInputFormatter(),
///   ],
/// )
/// ```
class CurrencyInputFormatter extends TextInputFormatter {
  final String currencyCode;

  CurrencyInputFormatter({this.currencyCode = 'VND'});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If empty, return as is
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // If no digits, return empty
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Parse to number
    final number = double.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    // Format with thousand separators
    final formatted = CurrencyFormatter.formatWithoutSymbol(number, currencyCode);

    // Always place cursor at the end for simplicity
    // This is the most user-friendly approach for currency input
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
