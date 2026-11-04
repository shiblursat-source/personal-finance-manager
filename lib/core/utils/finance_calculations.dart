import 'dart:math' as math;

/// Pure, unit-testable business logic derived from the Excel ledger.
class FinanceCalculations {
  FinanceCalculations._();

  /// Variance in every sheet of the ledger: Projected - Actual.
  /// Positive = under budget / saved, Negative = overspent.
  static double variance(double projected, double actual) => projected - actual;

  static double netSavings(double totalIncome, double totalExpense) => totalIncome - totalExpense;

  static double savingsRate(double income, double expense) {
    if (income <= 0) return 0;
    return ((income - expense) / income) * 100;
  }

  /// Whole months remaining to clear [balance] paying [monthlyPayment]/month.
  static int remainingMonthsForLoan(double balance, double monthlyPayment) {
    if (balance <= 0) return 0;
    if (monthlyPayment <= 0) return 0;
    return (balance / monthlyPayment).ceil();
  }

  /// Calendar months between two dates (inclusive of start month = end-start).
  static int monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  /// Balance after [paymentsMade] EMI payments, never below zero.
  static double balanceAfterPayments(double total, double monthlyPayment, int paymentsMade) {
    return math.max(0, total - (monthlyPayment * paymentsMade));
  }

  static double loanProgressPercent(double total, double balance) {
    if (total <= 0) return 0;
    return (((total - balance) / total) * 100).clamp(0, 100);
  }

  static double goalProgressPercent(double target, double saved) {
    if (target <= 0) return 0;
    return ((saved / target) * 100).clamp(0, 100);
  }

  static double lineTotal(double quantity, double unitPrice) => quantity * unitPrice;
  static double grossSalary({required double basic, required double houseRent, required double medical, required double transport}) => basic + houseRent + medical + transport;
}
