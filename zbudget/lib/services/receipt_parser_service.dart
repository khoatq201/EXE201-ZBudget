/// Service for parsing receipt data from OCR text
class ReceiptParserService {
  /// Parse receipt data from OCR text
  static ReceiptData parseReceipt(String ocrText) {
    return ReceiptData(
      amount: _extractAmount(ocrText),
      description: _extractDescription(ocrText),
      category: _predictCategory(ocrText),
      date: _extractDate(ocrText),
      storeName: _extractStoreName(ocrText),
      items: _extractItems(ocrText),
    );
  }

  /// Extract amount from text using multiple patterns
  static double _extractAmount(String text) {
    // Vietnamese currency patterns - Enhanced for Bách Hóa Xanh receipts
    final patterns = [
      // Pattern: Phải thanh toán: 40.100
      RegExp(
        r'(?:Phải thanh toán|Phai thanh toan|PHẢI THANH TOÁN)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      ),

      // Pattern: Tiền chuyển khoản: 40.100
      RegExp(
        r'(?:Tiền chuyển khoản|Tien chuyen khoan|TIỀN CHUYỂN KHOẢN)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      ),

      // Pattern: 1.000.000 ₫ or 1,000,000 VND
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*₫'),
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*VND'),
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*đ'),

      // Pattern: Total: 1.000.000
      RegExp(
        r'(?:Total|Tổng|Tong|TOTAL)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      ),

      // Pattern: Amount: 1.000.000
      RegExp(
        r'(?:Amount|Số tiền|So tien|AMOUNT)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      ),

      // Pattern: Grand Total: 1.000.000
      RegExp(
        r'(?:Grand Total|Tổng cộng|Tong cong|GRAND TOTAL)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      ),

      // Pattern: Look for amounts with Vietnamese currency symbols
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*[₫đVND]'),

      // Simple number pattern (fallback)
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match
            .group(1)!
            .replaceAll(',', '')
            .replaceAll('.', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    return 0.0;
  }

  /// Extract description from text
  static String _extractDescription(String text) {
    // Look for common receipt patterns
    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) return '';

    // Try to find store name or main description
    for (final line in lines) {
      final cleanLine = line.trim();

      // Skip lines that look like amounts
      if (RegExp(r'^\d+([.,]\d+)*\s*[₫VNDđ]?$').hasMatch(cleanLine)) continue;

      // Skip lines that look like dates
      if (RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(cleanLine))
        continue;

      // Skip lines that look like addresses
      if (cleanLine.contains('Địa chỉ') || cleanLine.contains('Address'))
        continue;

      // Skip lines that look like phone numbers
      if (RegExp(r'\d{3,4}[-.\s]?\d{3,4}[-.\s]?\d{3,4}').hasMatch(cleanLine))
        continue;

      // Take the first meaningful line as description
      if (cleanLine.length > 3 && cleanLine.length < 50) {
        return cleanLine;
      }
    }

    // Fallback: return first line
    return lines.isNotEmpty ? lines.first.trim() : '';
  }

  /// Predict category based on text content
  static String _predictCategory(String text) {
    final lowerText = text.toLowerCase();

    // Food and dining
    if (_containsAny(lowerText, [
      'ăn',
      'food',
      'restaurant',
      'cafe',
      'coffee',
      'nhà hàng',
      'nha hang',
      'quán',
      'quan',
      'bún',
      'bun',
      'phở',
      'pho',
      'cơm',
      'com',
      'pizza',
      'burger',
      'mcdonalds',
      'kfc',
      'lotteria',
      'jollibee',
    ])) {
      return 'food';
    }

    // Transportation
    if (_containsAny(lowerText, [
      'xăng',
      'gas',
      'taxi',
      'uber',
      'grab',
      'xe',
      'car',
      'bus',
      'metro',
      'điện',
      'dien',
      'fuel',
      'petrol',
      'gasoline',
      'parking',
      'đỗ xe',
      'do xe',
    ])) {
      return 'transport';
    }

    // Shopping
    if (_containsAny(lowerText, [
      'shop',
      'store',
      'mall',
      'siêu thị',
      'sieu thi',
      'supermarket',
      'coopmart',
      'big c',
      'lotte',
      'vincom',
      'aeon',
      'mua sắm',
      'mua sam',
      'clothes',
      'quần áo',
      'quan ao',
      'shoes',
      'giày',
      'giay',
    ])) {
      return 'shopping';
    }

    // Healthcare
    if (_containsAny(lowerText, [
      'thuốc',
      'thuoc',
      'pharmacy',
      'hospital',
      'clinic',
      'doctor',
      'bác sĩ',
      'bac si',
      'medical',
      'health',
      'y tế',
      'y te',
      'medicine',
      'drug',
      'nhà thuốc',
      'nha thuoc',
    ])) {
      return 'healthcare';
    }

    // Entertainment
    if (_containsAny(lowerText, [
      'cinema',
      'movie',
      'phim',
      'game',
      'game',
      'entertainment',
      'giải trí',
      'giai tri',
      'karaoke',
      'bar',
      'pub',
      'club',
      'discotheque',
      'rạp chiếu phim',
      'rap chieu phim',
    ])) {
      return 'entertainment';
    }

    // Utilities
    if (_containsAny(lowerText, [
      'điện',
      'dien',
      'nước',
      'nuoc',
      'internet',
      'wifi',
      'phone',
      'điện thoại',
      'dien thoai',
      'electricity',
      'water',
      'utility',
      'tiện ích',
      'tien ich',
      'bill',
      'hóa đơn',
      'hoa don',
    ])) {
      return 'utilities';
    }

    // Education
    if (_containsAny(lowerText, [
      'school',
      'university',
      'college',
      'education',
      'giáo dục',
      'giao duc',
      'book',
      'sách',
      'sach',
      'course',
      'khóa học',
      'khoa hoc',
      'tuition',
      'học phí',
      'hoc phi',
    ])) {
      return 'education';
    }

    return 'other';
  }

  /// Extract date from text
  static DateTime? _extractDate(String text) {
    final patterns = [
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);

          // Handle 2-digit years
          final fullYear = year < 100 ? 2000 + year : year;

          return DateTime(fullYear, month, day);
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  /// Extract store name from text
  static String _extractStoreName(String text) {
    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) return '';

    // Look for store names - prioritize known Vietnamese stores
    final storeKeywords = [
      'BÁCH HÓA XANH',
      'Bach Hoa Xanh',
      'Bach Hoa Xanh',
      'COOPMART',
      'Coopmart',
      'BIG C',
      'Big C',
      'LOTTE',
      'Lotte',
      'VINCOM',
      'Vincom',
      'AEON',
      'Aeon',
      'CIRCLE K',
      'Circle K',
      '7-ELEVEN',
      '7-Eleven',
    ];

    for (final line in lines) {
      final cleanLine = line.trim().toUpperCase();

      // Check for known store names
      for (final keyword in storeKeywords) {
        if (cleanLine.contains(keyword.toUpperCase())) {
          return line.trim();
        }
      }

      // Skip lines that look like amounts, dates, or addresses
      if (RegExp(r'^\d+([.,]\d+)*\s*[₫VNDđ]?$').hasMatch(line.trim())) continue;
      if (RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(line.trim()))
        continue;
      if (line.trim().contains('Địa chỉ') || line.trim().contains('Address'))
        continue;

      // Take the first meaningful line as store name
      if (line.trim().length > 2 && line.trim().length < 50) {
        return line.trim();
      }
    }

    return '';
  }

  /// Extract items from text (simplified)
  static List<String> _extractItems(String text) {
    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final items = <String>[];

    for (final line in lines) {
      final cleanLine = line.trim();

      // Skip lines that look like amounts, dates, or addresses
      if (RegExp(r'^\d+([.,]\d+)*\s*[₫VNDđ]?$').hasMatch(cleanLine)) continue;
      if (RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(cleanLine))
        continue;
      if (cleanLine.contains('Địa chỉ') || cleanLine.contains('Address'))
        continue;
      if (cleanLine.contains('Total') || cleanLine.contains('Tổng')) continue;

      // Add meaningful lines as items
      if (cleanLine.length > 2 && cleanLine.length < 100) {
        items.add(cleanLine);
      }
    }

    return items.take(5).toList(); // Limit to 5 items
  }

  /// Helper method to check if text contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}

/// Receipt data model
class ReceiptData {
  final double amount;
  final String description;
  final String category;
  final DateTime? date;
  final String storeName;
  final List<String> items;

  ReceiptData({
    required this.amount,
    required this.description,
    required this.category,
    this.date,
    required this.storeName,
    required this.items,
  });

  bool get hasValidAmount => amount > 0;
  bool get hasDescription => description.isNotEmpty;
  bool get hasStoreName => storeName.isNotEmpty;
  bool get hasItems => items.isNotEmpty;

  /// Get confidence score for the parsed data
  double get confidence {
    double score = 0.0;

    if (hasValidAmount) score += 0.4;
    if (hasDescription) score += 0.3;
    if (hasStoreName) score += 0.2;
    if (hasItems) score += 0.1;

    return score;
  }
}
