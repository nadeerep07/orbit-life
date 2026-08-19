import 'dart:developer' as dev;

class ParsedReceipt {
  final double amount;
  final String merchant;
  final DateTime date;
  final String rawText;

  const ParsedReceipt({
    required this.amount,
    required this.merchant,
    required this.date,
    required this.rawText,
  });

  @override
  String toString() {
    return 'ParsedReceipt(amount: $amount, merchant: $merchant, date: $date)';
  }
}

class OcrParserService {
  /// Parses raw text extracted by OCR and returns structured receipt details.
  static ParsedReceipt parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double amount = 0.0;
    String merchant = '';
    DateTime date = DateTime.now();

    try {
      amount = _parseAmount(lines);
      merchant = _parseMerchant(lines);
      date = _parseDate(lines);
    } catch (e, stack) {
      dev.log('Error parsing raw OCR text: $e', error: e, stackTrace: stack);
    }

    return ParsedReceipt(
      amount: amount,
      merchant: merchant,
      date: date,
      rawText: text,
    );
  }

  static double _parseAmount(List<String> lines) {
    // 1. Look for currency patterns: e.g. ₹ 250.00, Rs. 400, $12.99
    // Matches: ₹, Rs., Rs, $, followed by decimal or integer
    final currencyRegex = RegExp(
      r'(?:₹|Rs\.?|Rs|\$)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)',
      caseSensitive: false,
    );

    final List<double> candidates = [];
    final List<double> priorityCandidates = [];

    for (final line in lines) {
      final matches = currencyRegex.allMatches(line);
      for (final match in matches) {
        final valStr = match.group(1)?.replaceAll(',', '') ?? '0';
        final val = double.tryParse(valStr);
        if (val != null && val > 0) {
          final cleanLine = line.toLowerCase();
          // If the line contains typical payment/receipt success keywords, prioritize it
          if (cleanLine.contains('total') ||
              cleanLine.contains('paid') ||
              cleanLine.contains('amount') ||
              cleanLine.contains('success') ||
              cleanLine.contains('debited')) {
            priorityCandidates.add(val);
          } else {
            candidates.add(val);
          }
        }
      }
    }

    if (priorityCandidates.isNotEmpty) {
      // Return the highest priority candidate (which is usually the total amount paid)
      return priorityCandidates.reduce((curr, next) => curr > next ? curr : next);
    }

    if (candidates.isNotEmpty) {
      // Fallback to highest numeric value found with a currency prefix
      return candidates.reduce((curr, next) => curr > next ? curr : next);
    }

    // 2. Secondary fallback: Look for plain decimal formats like 250.00, 1500.50
    final plainDecimalRegex = RegExp(r'\b\d+\.\d{2}\b');
    for (final line in lines) {
      final matches = plainDecimalRegex.allMatches(line);
      for (final match in matches) {
        final val = double.tryParse(match.group(0) ?? '0');
        if (val != null && val > 0) {
          candidates.add(val);
        }
      }
    }

    if (candidates.isNotEmpty) {
      return candidates.reduce((curr, next) => curr > next ? curr : next);
    }

    return 0.0;
  }

  static String _parseMerchant(List<String> lines) {
    // 1. Check for standard UPI/banking success screenshots merchant prefixes
    final prefixes = [
      RegExp(r'\b(?:paid successfully to|paid to|successfully transferred to|payment successful to|payment completed to|payment to|to:)\s*(.*)', caseSensitive: false),
      RegExp(r'\b(?:merchant|receiver|payee):\s*(.*)', caseSensitive: false),
      RegExp(r'\bto\b\s*(.*)', caseSensitive: false),
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final regex in prefixes) {
        final match = regex.firstMatch(line);
        if (match != null) {
          var name = match.group(1)?.trim() ?? '';
          // If name is empty, try the next line!
          if (name.isEmpty && i + 1 < lines.length) {
            name = lines[i + 1].trim();
          }
          if (name.length > 2 && !_isIgnorableWord(name) && !_isAmountLine(name)) {
            return _cleanMerchantName(name);
          }
        }
      }
    }

    // 2. Fallback for printed receipts:
    // The merchant is usually in the first 3 lines of the receipt.
    // Skip lines that are just numbers, dates, emails, websites, or contain common receipt labels.
    for (int i = 0; i < lines.length && i < 4; i++) {
      final line = lines[i];
      if (line.length > 2 &&
          !_isIgnorableLine(line) &&
          !line.contains('@') &&
          !line.contains('www.') &&
          !line.contains('.com') &&
          !_isAmountLine(line)) {
        return _cleanMerchantName(line);
      }
    }

    return 'Unknown Merchant';
  }

  static bool _isAmountLine(String line) {
    final clean = line.toLowerCase();
    return clean.contains('₹') ||
        clean.contains('rs') ||
        clean.contains('\$') ||
        clean.contains('amount') ||
        clean.contains('total') ||
        RegExp(r'\b(?:am|pm)\b').hasMatch(clean) ||
        RegExp(r'\d{1,2}:\d{2}').hasMatch(clean) ||
        RegExp(r'^\d+$').hasMatch(line);
  }

  static DateTime _parseDate(List<String> lines) {
    // Look for common date patterns
    // 1. DD/MM/YYYY or DD-MM-YYYY
    final dateSlashRegex = RegExp(r'\b(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})\b');
    // 2. YYYY-MM-DD
    final dateIsoRegex = RegExp(r'\b(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})\b');
    // 3. DD Month YYYY (e.g. 22 July 2026 or 22 Jul 2026)
    final dateWordRegex = RegExp(
      r'\b(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{4})\b',
      caseSensitive: false,
    );

    for (final line in lines) {
      // Match DD/MM/YYYY
      var match = dateSlashRegex.firstMatch(line);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '');
        final month = int.tryParse(match.group(2) ?? '');
        final year = int.tryParse(match.group(3) ?? '');
        if (day != null && month != null && year != null) {
          // Adjust for simple month/day ordering if needed, default to day/month
          if (month <= 12 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
      }

      // Match YYYY-MM-DD
      match = dateIsoRegex.firstMatch(line);
      if (match != null) {
        final year = int.tryParse(match.group(1) ?? '');
        final month = int.tryParse(match.group(2) ?? '');
        final day = int.tryParse(match.group(3) ?? '');
        if (year != null && month != null && day != null) {
          if (month <= 12 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
      }

      // Match DD Month YYYY
      match = dateWordRegex.firstMatch(line);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '');
        final monthStr = match.group(2)?.toLowerCase() ?? '';
        final year = int.tryParse(match.group(3) ?? '');
        final month = _monthStringToInt(monthStr);
        if (day != null && month > 0 && year != null) {
          return DateTime(year, month, day);
        }
      }
    }

    return DateTime.now();
  }

  static bool _isIgnorableWord(String word) {
    final w = word.toLowerCase();
    return w == 'success' ||
        w == 'completed' ||
        w == 'successful' ||
        w == 'transaction';
  }

  static bool _isIgnorableLine(String line) {
    final l = line.toLowerCase();
    return l.contains('invoice') ||
        l.contains('receipt') ||
        l.contains('bill') ||
        l.contains('tax') ||
        l.contains('tel:') ||
        l.contains('phone:') ||
        l.contains('payment');
  }

  static String _cleanMerchantName(String name) {
    // Strip trailing symbols, extra whitespace, or common billing line noise
    var clean = name
        .replaceAll(RegExp(r'[^\w\s\.\-\(\)]'), '')
        .trim();
    if (clean.length > 30) {
      clean = '${clean.substring(0, 30).trim()}...';
    }
    return clean;
  }

  static int _monthStringToInt(String m) {
    if (m.startsWith('jan')) return 1;
    if (m.startsWith('feb')) return 2;
    if (m.startsWith('mar')) return 3;
    if (m.startsWith('apr')) return 4;
    if (m.startsWith('may')) return 5;
    if (m.startsWith('jun')) return 6;
    if (m.startsWith('jul')) return 7;
    if (m.startsWith('aug')) return 8;
    if (m.startsWith('sep')) return 9;
    if (m.startsWith('oct')) return 10;
    if (m.startsWith('nov')) return 11;
    if (m.startsWith('dec')) return 12;
    return 0;
  }
}
