import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final selectedYearProvider = StateProvider<int>((_) => DateTime.now().year);
final selectedMonthProvider = StateProvider<int>((_) => DateTime.now().month);

final ledgerEntriesProvider = StreamProvider<List<LedgerEntry>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final y = ref.watch(selectedYearProvider);
  final m = ref.watch(selectedMonthProvider);
  return db.watchLedger(y, m);
});

final allLoansProvider = StreamProvider<List<Loan>>((ref) { final db = ref.watch(appDatabaseProvider); return db.select(db.loans).watch(); });
final salaryListProvider = StreamProvider<List<SalaryStructure>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.salaryStructures)..orderBy([(t) => OrderingTerm.desc(t.year), (t) => OrderingTerm.desc(t.month)])).watch();
});
final pfListProvider = StreamProvider<List<PfEntry>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.pfEntries)..orderBy([(t) => OrderingTerm.desc(t.year), (t) => OrderingTerm.desc(t.month)])).watch();
});
final pfLoansProvider = StreamProvider<List<PfLoanEntry>>((ref) { final db = ref.watch(appDatabaseProvider); return db.select(db.pfLoanEntries).watch(); });
final occasionBudgetsProvider = StreamProvider<List<OccasionBudget>>((ref) { final db = ref.watch(appDatabaseProvider); return db.select(db.occasionBudgets).watch(); });
final occasionItemsProvider = StreamProvider<List<OccasionItem>>((ref) { final db = ref.watch(appDatabaseProvider); return db.select(db.occasionItems).watch(); });
final futureGoalsProvider = StreamProvider<List<FutureGoal>>((ref) { final db = ref.watch(appDatabaseProvider); return db.select(db.futureGoals).watch(); });
