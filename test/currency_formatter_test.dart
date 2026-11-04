import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_manager/core/utils/currency_formatter.dart';
void main() {
  group('CurrencyFormatter', () {
    test('formats BDT with symbol and South-Asian grouping', () { expect(CurrencyFormatter.bdt(85000), contains('৳')); expect(CurrencyFormatter.bdt(100000), contains('1,00,000')); });
    test('parses formatted input back to a number', () { expect(CurrencyFormatter.parse('৳ 1,200.50'), 1200.5); expect(CurrencyFormatter.parse(''), 0); expect(CurrencyFormatter.parse('abc'), 0); });
    test('compact uses K / L / Cr', () { expect(CurrencyFormatter.compact(1500), contains('K')); expect(CurrencyFormatter.compact(250000), contains('L')); expect(CurrencyFormatter.compact(15000000), contains('Cr')); });
  });
}
