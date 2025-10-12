import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter for currency input fields
///
/// Automatically formats numbers as user types with thousand separators
/// Supports VND format (1.000.000) and USD format (1,000,000)
class CurrencyInputFormatter extends TextInputFormatter {
  final String currencyCode;
  final bool allowDecimals;

  CurrencyInputFormatter({
    this.currencyCode = 'VND',
    this.allowDecimals = false,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, return it as is
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-numeric characters except decimal point
    String cleaned = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // For VND, remove decimal points since VND doesn't use decimals
    if (currencyCode == 'VND' || !allowDecimals) {
      cleaned = cleaned.replaceAll('.', '');
    }

    // Parse the number
    final number = double.tryParse(cleaned);
    if (number == null || number < 0) {
      return oldValue; // Revert to old value if invalid
    }

    // Format the number with thousand separators
    String formatted;
    if (currencyCode == 'VND') {
      // VND format: 1.000.000
      final formatter = NumberFormat('#,##0', 'vi_VN');
      formatted = formatter.format(number.round());
    } else {
      // USD/EUR format: 1,000,000
      final formatter = NumberFormat(
        '#,##0${allowDecimals ? '.00' : ''}',
        'en_US',
      );
      formatted = formatter.format(number);
    }

    // Calculate cursor position
    int cursorPosition = formatted.length;

    // Try to maintain cursor position relative to the end
    final oldLength = oldValue.text.length;
    final newLength = newValue.text.length;
    final lengthDiff = newLength - oldLength;

    if (lengthDiff > 0) {
      // User added characters, position cursor at the end
      cursorPosition = formatted.length;
    } else if (lengthDiff < 0) {
      // User deleted characters, try to maintain relative position
      final oldCursorPos = oldValue.selection.baseOffset;
      final oldFormattedLength = _getFormattedLength(oldValue.text);
      if (oldFormattedLength > 0) {
        final ratio = oldCursorPos / oldFormattedLength;
        cursorPosition = (formatted.length * ratio).round().clamp(
          0,
          formatted.length,
        );
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  int _getFormattedLength(String text) {
    // Remove formatting to get the actual number length
    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length;
  }
}

/// TextInputFormatter specifically for VND currency
class VNDInputFormatter extends CurrencyInputFormatter {
  VNDInputFormatter() : super(currencyCode: 'VND', allowDecimals: false);
}

/// TextInputFormatter specifically for USD currency
class USDInputFormatter extends CurrencyInputFormatter {
  USDInputFormatter() : super(currencyCode: 'USD', allowDecimals: true);
}

/// TextInputFormatter for percentage input (0-100)
class PercentageInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-numeric characters
    String cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) {
      return newValue;
    }

    // Parse the number
    final number = double.tryParse(cleaned);
    if (number == null) {
      return oldValue;
    }

    // Limit to 0-100
    final clampedNumber = number.clamp(0, 100);

    // If the number was clamped, use the clamped value
    if (clampedNumber != number) {
      return TextEditingValue(
        text: clampedNumber.toString(),
        selection: TextSelection.collapsed(
          offset: clampedNumber.toString().length,
        ),
      );
    }

    return newValue;
  }
}

/// Helper functions to create formatted TextFormFields
class CurrencyInputHelper {
  /// Create a VND currency formatted TextFormField
  static Widget createVNDField({
    required TextEditingController controller,
    required InputDecoration decoration,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String?)? onSaved,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: decoration,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      inputFormatters: [VNDInputFormatter(), ...?inputFormatters],
      keyboardType: keyboardType ?? TextInputType.number,
    );
  }

  /// Create a USD currency formatted TextFormField
  static Widget createUSDField({
    required TextEditingController controller,
    required InputDecoration decoration,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String?)? onSaved,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: decoration,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      inputFormatters: [USDInputFormatter(), ...?inputFormatters],
      keyboardType:
          keyboardType ?? TextInputType.numberWithOptions(decimal: true),
    );
  }

  /// Create a percentage formatted TextFormField
  static Widget createPercentageField({
    required TextEditingController controller,
    required InputDecoration decoration,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String?)? onSaved,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: decoration,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      inputFormatters: [PercentageInputFormatter(), ...?inputFormatters],
      keyboardType: keyboardType ?? TextInputType.number,
    );
  }
}
