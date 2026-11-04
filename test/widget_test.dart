import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_manager/core/utils/currency_formatter.dart';
void main() { test('smoke: formatter loads', () { expect(formatBDT(1000), contains('৳')); }); }
