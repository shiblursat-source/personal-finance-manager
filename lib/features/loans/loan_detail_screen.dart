import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/finance_calculations.dart';
import '../../data/providers.dart';
import 'loans_screen.dart';

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});
  final int loanId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final loansAsync = ref.watch(allLoansProvider);
    return loansAsync.when(loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())), error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))), data: (loans) {
      final matches = loans.where((l) => l.id == loanId).toList(); final loan = matches.isEmpty ? null : matches.first;
      if (loan == null) return const Scaffold(body: Center(child: Text('Loan not found')));
      final rem = FinanceCalculations.remainingMonthsForLoan(loan.balanceAmount, loan.monthlyPayment);
      return Scaffold(appBar: AppBar(title: Text(loan.name), actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => showLoanForm(context, ref, existing: loan)), IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await (db.delete(db.loans)..where((t) => t.id.equals(loan.id))).go(); if (context.mounted) Navigator.pop(context); })]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Total: ${CurrencyFormatter.bdt(loan.totalAmount)}', style: Theme.of(context).textTheme.titleMedium),
          Text('Balance (B.A): ${CurrencyFormatter.bdt(loan.balanceAmount)}'),
          Text('Monthly Payment (P.A): ${CurrencyFormatter.bdt(loan.monthlyPayment)}'),
          Text('Monthly Savings (Sonchoy): ${CurrencyFormatter.bdt(loan.monthlySavings)}'),
          Text('Start: ${loan.startDate.toString().split(' ').first}  •  End: ${loan.endDate.toString().split(' ').first}'),
          Text('Remaining Months: $rem', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12), LinearProgressIndicator(value: FinanceCalculations.loanProgressPercent(loan.totalAmount, loan.balanceAmount) / 100),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: loan.isActive ? () => db.markLoanPaid(loan, year: DateTime.now().year, month: DateTime.now().month) : null, icon: const Icon(Icons.check), label: const Text('Mark as Paid (this month)')),
          const SizedBox(height: 20), Text('Payment History', style: Theme.of(context).textTheme.titleMedium),
          StreamBuilder(stream: (db.select(db.loanPayments)..where((t) => t.loanId.equals(loanId))..orderBy([(t) => OrderingTerm.desc(t.paidAt)])).watch(), builder: (_, snap) { if (!snap.hasData) return const CircularProgressIndicator(); final list = snap.data!; if (list.isEmpty) return const Text('No payments recorded yet.'); return Column(children: [for (final pay in list) ListTile(title: Text(CurrencyFormatter.bdt(pay.amount)), subtitle: Text('${pay.year}-${pay.month.toString().padLeft(2, '0')}'))]); }),
        ]));
    });
  }
}
