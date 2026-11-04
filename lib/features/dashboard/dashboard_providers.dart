import '../../data/database.dart';

class MonthlySummary {
  const MonthlySummary({required this.income, required this.expense, required this.projectedIncome, required this.projectedExpense, required this.expenseByCategory});
  final double income, expense, projectedIncome, projectedExpense;
  final Map<String, double> expenseByCategory;
  double get netSavings => income - expense;
  factory MonthlySummary.fromEntries(List<LedgerEntry> entries) {
    double inc = 0, exp = 0, pInc = 0, pExp = 0; final map = <String, double>{};
    for (final e in entries) {
      if (e.type == 'income') { inc += e.actualAmount; pInc += e.projectedAmount; }
      else { exp += e.actualAmount; pExp += e.projectedAmount; map[e.category] = (map[e.category] ?? 0) + e.actualAmount; }
    }
    return MonthlySummary(income: inc, expense: exp, projectedIncome: pInc, projectedExpense: pExp, expenseByCategory: map);
  }
}
