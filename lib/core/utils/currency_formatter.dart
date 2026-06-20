import 'package:intl/intl.dart';

String currencySymbol = '₹';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatNoDecimals(double amount) {
    final formatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0);
    return formatter.format(amount);
  }
}
