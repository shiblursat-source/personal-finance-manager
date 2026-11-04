import 'package:intl/intl.dart';

/// BDT (৳) formatting using South-Asian (lakh/crore style) digit grouping.
/// `en_IN` grouping matches the grouping used in Bangladesh; `bn_BD` is kept
/// as an alternative locale for Bengali numerals when explicitly requested.
class CurrencyFormatter {
  CurrencyFormatter._();
  static final NumberFormat _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '৳ ', decimalDigits: 0);
  static final NumberFormat _fmt2 = NumberFormat.currency(locale: 'en_IN', symbol: '৳ ', decimalDigits: 2);
  static final NumberFormat _plain = NumberFormat('#,##0', 'en_IN');

  static String bdt(num value, {bool decimals = false}) => decimals ? _fmt2.format(value) : _fmt.format(value);
  static String plain(num value) => _plain.format(value);

  static String compact(num value) {
    final v = value.abs();
    String suffix; double scaled;
    if (v >= 10000000) { suffix = ' Cr'; scaled = value / 10000000; }
    else if (v >= 100000) { suffix = ' L'; scaled = value / 100000; }
    else if (v >= 1000) { suffix = ' K'; scaled = value / 1000; }
    else { return bdt(value); }
    return '৳ ${scaled.toStringAsFixed(scaled.abs() >= 100 ? 0 : 1)}$suffix';
  }

  static double parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
String formatBDT(num value) => CurrencyFormatter.bdt(value);
