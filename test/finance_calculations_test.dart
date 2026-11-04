import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_manager/core/utils/finance_calculations.dart';
void main() {
  group('FinanceCalculations', () {
    test('variance = projected - actual', () { expect(FinanceCalculations.variance(15000, 14200), 800); expect(FinanceCalculations.variance(1000, 1200), -200); });
    test('net savings and rate', () { expect(FinanceCalculations.netSavings(103500, 67400), 36100); expect(FinanceCalculations.savingsRate(0, 100), 0); });
    test('remaining months for a loan rounds up and stops at zero', () { expect(FinanceCalculations.remainingMonthsForLoan(120000, 10000), 12); expect(FinanceCalculations.remainingMonthsForLoan(125000, 10000), 13); expect(FinanceCalculations.remainingMonthsForLoan(0, 10000), 0); expect(FinanceCalculations.remainingMonthsForLoan(5000, 0), 0); });
    test('balance after payments never goes negative', () { expect(FinanceCalculations.balanceAfterPayments(200000, 10000, 8), 120000); expect(FinanceCalculations.balanceAfterPayments(200000, 10000, 99), 0); });
    test('months between dates', () { expect(FinanceCalculations.monthsBetween(DateTime(2025, 1), DateTime(2026, 1)), 12); });
    test('gross salary sums all allowances', () { expect(FinanceCalculations.grossSalary(basic: 50000, houseRent: 25000, medical: 5000, transport: 5000), 85000); });
    test('goal and loan progress clamp to 0-100', () { expect(FinanceCalculations.goalProgressPercent(100, 150), 100); expect(FinanceCalculations.loanProgressPercent(200000, 120000), 40); });
    test('line total = qty x unit price', () { expect(FinanceCalculations.lineTotal(25, 68), 1700); });
  });
}
