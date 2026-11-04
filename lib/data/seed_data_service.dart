import 'package:drift/drift.dart';
import 'database.dart';

/// Inserts realistic first-run demo data ONCE (guarded by an empty ledger),
/// so the app never opens empty. All amounts are sample BDT figures the user
/// can edit/delete — they mirror the named sheets in his Excel ledger.
class SeedDataService {
  SeedDataService(this.db);
  final AppDatabase db;

  Future<void> seedIfEmpty() async {
    final existing = await db.select(db.ledgerEntries).get();
    if (existing.isNotEmpty) return;
    final now = DateTime.now();
    final y = now.year; final m = now.month;
    Future<void> entry(String type, String cat, double proj, double actual) => db.into(db.ledgerEntries).insert(LedgerEntriesCompanion.insert(year: y, month: m, type: type, category: cat, projectedAmount: Value(proj), actualAmount: Value(actual)));
    await entry('income', 'Earn 1 (Primary Salary)', 85000, 85000);
    await entry('income', 'Earn 2 (Secondary/Online)', 15000, 12000);
    await entry('income', 'Overtime (EOT)', 8000, 6500);
    await entry('expense', 'Bari Vara (House Rent)', 18000, 18000);
    await entry('expense', 'Barite Send (Family Remittance)', 20000, 20000);
    await entry('expense', 'Dukan Bill (Grocery Store)', 12000, 11500);
    await entry('expense', 'Utility - Current Bill', 2500, 2300);
    await entry('expense', 'Utility - Internet', 1000, 1000);
    await entry('expense', 'Utility - Dish Bill', 400, 400);
    await entry('expense', 'Bazar (Daily Food)', 15000, 14200);

    Future<int> loan(String name, String type, double total, double pa, double ba, double sonchoy) => db.into(db.loans).insert(LoansCompanion.insert(name: name, type: type, totalAmount: total, monthlyPayment: pa, balanceAmount: ba, monthlySavings: Value(sonchoy), startDate: DateTime(y - 1, 1, 1), endDate: DateTime(y + 1, 12, 1)));
    await loan('Mehedi loan', 'personal', 200000, 10000, 120000, 2000);
    await loan('BRAC Bank Credit Card', 'credit_card', 150000, 12000, 68000, 0);
    await loan('LankaBangla Credit Card', 'credit_card', 100000, 8000, 45000, 0);
    await loan('City Bank Card', 'credit_card', 120000, 9000, 30000, 0);

    await db.into(db.salaryStructures).insert(SalaryStructuresCompanion.insert(year: y, month: m, basicSalary: const Value(50000), houseRentAllowance: const Value(25000), medicalAllowance: const Value(5000), transportAllowance: const Value(5000)));
    await db.into(db.pfEntries).insert(PfEntriesCompanion.insert(year: y, month: m, monthlyDeduction: const Value(5000), employerContribution: const Value(5000), cumulativeBalance: const Value(185000)));

    final eidId = await db.into(db.occasionBudgets).insert(OccasionBudgetsCompanion.insert(type: 'eid', title: 'Eid-ul-Fitr $y', year: y, incomeBudget: const Value(60000)));
    for (final (person, amt) in [('Abba', 8000.0), ('Maa', 8000.0), ('Bou', 12000.0), ('Omor', 5000.0), ('Ramim', 5000.0), ('Eid Bazar', 10000.0), ('Eid Transport', 4000.0)]) {
      await db.into(db.occasionItems).insert(OccasionItemsCompanion.insert(budgetId: eidId, personOrCategory: person, budgetedAmount: Value(amt), actualAmount: Value(amt * 0.9)));
    }
    final tourId = await db.into(db.occasionBudgets).insert(OccasionBudgetsCompanion.insert(type: 'tour', title: "Cox's Bazar Family Tour $y", year: y, incomeBudget: const Value(80000)));
    for (final (cat, amt) in [('Bus Rent', 18000.0), ('Hotel Accommodation', 25000.0), ('Food', 20000.0), ('Sightseeing', 8000.0), ('Miscellaneous', 5000.0)]) {
      await db.into(db.occasionItems).insert(OccasionItemsCompanion.insert(budgetId: tourId, personOrCategory: cat, budgetedAmount: Value(amt)));
    }
    for (final (item, qty, unit, price) in [('Rice', 25.0, 'kg', 68.0), ('Oil', 5.0, 'litre', 190.0), ('Lentils (Dal)', 3.0, 'kg', 140.0), ('Eggs', 30.0, 'pcs', 13.0), ('Spices', 1.0, 'pack', 600.0)]) {
      await db.into(db.bazarShopItems).insert(BazarShopItemsCompanion.insert(year: y, month: m, itemName: item, quantity: Value(qty), unit: Value(unit), unitPrice: Value(price)));
    }
    for (final (item, qty, unit, price, paid) in [('Bricks', 10000.0, 'pcs', 12.0, 60000.0), ('Sand', 500.0, 'cft', 55.0, 10000.0), ('Rod (Steel)', 2.0, 'ton', 92000.0, 50000.0), ('Cement', 300.0, 'bag', 560.0, 40000.0), ('Daily Labor', 60.0, 'day', 800.0, 20000.0), ('Water Tank', 1.0, 'pcs', 18000.0, 0.0)]) {
      await db.into(db.homeConstructionItems).insert(HomeConstructionItemsCompanion.insert(itemName: item, quantity: Value(qty), unit: Value(unit), unitPrice: Value(price), paidAmount: Value(paid)));
    }
    for (final (title, target, saved) in [('Land Purchase', 3000000.0, 450000.0), ('House Building', 5000000.0, 300000.0), ('Bank Fixed Deposit (FD)', 500000.0, 200000.0)]) {
      await db.into(db.futureGoals).insert(FutureGoalsCompanion.insert(title: title, targetAmount: target, savedAmount: Value(saved), deadline: Value(DateTime(y + 3, 12, 31))));
    }
  }
}
