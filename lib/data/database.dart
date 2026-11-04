import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Tables — one per Excel sheet-group from the original 32-sheet ledger.
// Run codegen after changing this file:
//   dart run build_runner build --delete-conflicting-outputs
// ---------------------------------------------------------------------------

class LedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()(); // 1-12
  TextColumn get type => text()(); // income | expense
  TextColumn get category => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  RealColumn get projectedAmount => real().withDefault(const Constant(0))();
  RealColumn get actualAmount => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // e.g. Mehedi loan, BRAC Bank Credit Card
  TextColumn get type => text()(); // personal | credit_card
  RealColumn get totalAmount => real()();
  RealColumn get monthlyPayment => real()(); // P.A
  RealColumn get balanceAmount => real()(); // B.A
  RealColumn get monthlySavings => real().withDefault(const Constant(0))(); // Sonchoy
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
}

class LoanPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get loanId => integer().references(Loans, #id, onDelete: KeyAction.cascade)();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}

class SalaryStructures extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  RealColumn get basicSalary => real().withDefault(const Constant(0))();
  RealColumn get houseRentAllowance => real().withDefault(const Constant(0))();
  RealColumn get medicalAllowance => real().withDefault(const Constant(0))();
  RealColumn get transportAllowance => real().withDefault(const Constant(0))();
  RealColumn get otherAllowance => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
}

class PfEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  RealColumn get monthlyDeduction => real().withDefault(const Constant(0))();
  RealColumn get employerContribution => real().withDefault(const Constant(0))();
  RealColumn get cumulativeBalance => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
}

class PfLoanEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get totalLoanAmount => real()();
  RealColumn get monthlyRepayment => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get startDate => dateTime()();
  TextColumn get note => text().nullable()();
}

class OccasionBudgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // eid | tour
  TextColumn get title => text()(); // e.g. Eid-ul-Fitr 2026, Cox's Bazar Tour
  IntColumn get year => integer()();
  RealColumn get incomeBudget => real().withDefault(const Constant(0))(); // bonus / trip fund
  TextColumn get note => text().nullable()();
}

class OccasionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId => integer().references(OccasionBudgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get personOrCategory => text()(); // Abba, Maa, Hotel, Bus Rent...
  RealColumn get budgetedAmount => real().withDefault(const Constant(0))();
  RealColumn get actualAmount => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
}

class BazarShopItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  TextColumn get itemName => text()();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get unitPrice => real().withDefault(const Constant(0))();
  RealColumn get actualCost => real().withDefault(const Constant(0))();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
}

class HomeConstructionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemName => text()();
  TextColumn get unit => text().withDefault(const Constant(''))();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
}

class FutureGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get note => text().nullable()();
}

@DriftDatabase(tables: [LedgerEntries, Loans, LoanPayments, SalaryStructures, PfEntries, PfLoanEntries, OccasionBudgets, OccasionItems, BazarShopItems, HomeConstructionItems, FutureGoals])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) async => m.createAll());

  // --- Ledger helpers ---
  Stream<List<LedgerEntry>> watchLedger(int year, int month) =>
      (select(ledgerEntries)..where((t) => t.year.equals(year) & t.month.equals(month))..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Future<List<LedgerEntry>> allLedger() => select(ledgerEntries).get();

  // --- Loans: Mark as Paid (deduct P.A from B.A) ---
  Future<void> markLoanPaid(Loan loan, {required int year, required int month}) async {
    await transaction(() async {
      await into(loanPayments).insert(LoanPaymentsCompanion.insert(loanId: loan.id, year: year, month: month, amount: loan.monthlyPayment));
      final newBalance = (loan.balanceAmount - loan.monthlyPayment).clamp(0, double.infinity).toDouble();
      await (update(loans)..where((t) => t.id.equals(loan.id))).write(LoansCompanion(balanceAmount: Value(newBalance), isActive: Value(newBalance > 0)));
    });
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'personal_finance.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
