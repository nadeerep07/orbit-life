import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_pro/core/services/ocr_parser_service.dart';

void main() {
  group('OcrParserService Tests', () {
    test('Parse Google Pay UPI Screenshot', () {
      const rawText = '''
12:04 PM
Payment successful to
Starbucks Coffee
₹ 250.00
UPI Ref No: 6290119284
Completed on 22 July 2026
''';
      final result = OcrParserService.parse(rawText);
      expect(result.amount, equals(250.00));
      expect(result.merchant, equals('Starbucks Coffee'));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(7));
      expect(result.date.day, equals(22));
    });

    test('Parse PhonePe Screenshot', () {
      const rawText = '''
Paid successfully to
Dominos Pizza
Rs. 450.50
Completed on: 22-07-2026
''';
      final result = OcrParserService.parse(rawText);
      expect(result.amount, equals(450.50));
      expect(result.merchant, equals('Dominos Pizza'));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(7));
      expect(result.date.day, equals(22));
    });

    test('Parse Paytm Screenshot', () {
      const rawText = '''
Successfully transferred to
Amazon Pay Merchant
₹ 1,500.00
Date: 22/07/2026
''';
      final result = OcrParserService.parse(rawText);
      expect(result.amount, equals(1500.00));
      expect(result.merchant, equals('Amazon Pay Merchant'));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(7));
      expect(result.date.day, equals(22));
    });

    test('Parse Printed Supermarket Receipt', () {
      const rawText = '''
WELCOME TO WALMART STORE #104
TAX INVOICE
1x Grocery Items - 45.00
Total Amount: ₹ 45.00
2026-07-22 14:32:00
''';
      final result = OcrParserService.parse(rawText);
      expect(result.amount, equals(45.00));
      expect(result.merchant, equals('WALMART STORE 104'));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(7));
      expect(result.date.day, equals(22));
    });
  });
}
