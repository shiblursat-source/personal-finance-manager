import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/finance_calculations.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(allLoansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Loans & Credit Cards')),
      body: loansAsync.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('Error: $e')), data: (loans) {
        if (loans.isEmpty) return const EmptyState(message: 'No loans yet. Tap + to add a personal loan or credit card.', icon: Icons.credit_card_off_outlined);
        return ListView.builder(itemCount: loans.length, itemBuilder: (_, i) {
          final l = loans[i]; final rem = FinanceCalculations.remainingMonthsForLoan(l.balanceAmount, l.monthlyPayment); final prog = FinanceCalculations.loanProgressPercent(l.totalAmount, l.balanceAmount);
          return Card(child: ListTile(
            title: Text(l.name), subtitle: Text('${l.type == 'personal' ? 'Personal Loan' : 'Credit Card'} • P.A ${CurrencyFormatter.bdt(l.monthlyPayment)}/mo • Sonchoy ${CurrencyFormatter.bdt(l.monthlySavings)}\nBalance (B.A): ${CurrencyFormatter.bdt(l.balanceAmount)} • Remaining: $rem months • ${prog.toStringAsFixed(0)}% paid'),
            trailing: FilledButton.tonal(onPressed: l.isActive ? () async { await ref.read(appDatabaseProvider).markLoanPaid(l, year: ref.read(selectedYearProvider), month: ref.read(selectedMonthProvider)); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('EMI paid for ${l.name}'))); } : null, child: const Text('Mark Paid')),
            onTap: () => context.go('/loans/${l.id}'),
          ));
        });
      }),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showLoanForm(context, ref), icon: const Icon(Icons.add), label: const Text('Add Loan')),
    );
  }
}

Future<void> showLoanForm(BuildContext context, WidgetRef ref, {Loan? existing}) async {
  final name = TextEditingController(text: existing?.name ?? ''); final total = TextEditingController(text: existing?.totalAmount.toStringAsFixed(0) ?? ''); final pa = TextEditingController(text: existing?.monthlyPayment.toStringAsFixed(0) ?? ''); final sonchoy = TextEditingController(text: existing?.monthlySavings.toStringAsFixed(0) ?? ''); var type = existing?.type ?? 'personal';
  await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(title: Text(existing == null ? 'Add Loan / Card' : 'Edit Loan'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
    TextField(controller: name, decoration: const InputDecoration(labelText: 'Name (e.g. BRAC Bank Credit Card)')),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Type'), items: const [DropdownMenuItem(value: 'personal', child: Text('Personal Loan')), DropdownMenuItem(value: 'credit_card', child: Text('Credit Card'))], onChanged: (v) => setState(() => type = v ?? 'personal')),
    const SizedBox(height: 10), TextField(controller: total, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Loan Amount (৳)')),
    const SizedBox(height: 10), TextField(controller: pa, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Payment P.A (৳)')),
    const SizedBox(height: 10), TextField(controller: sonchoy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Savings Sonchoy (৳)')),
  ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async {
    final db = ref.read(appDatabaseProvider); final totalVal = CurrencyFormatter.parse(total.text);
    if (existing == null) { await db.into(db.loans).insert(LoansCompanion.insert(name: name.text.trim(), type: type, totalAmount: totalVal, monthlyPayment: CurrencyFormatter.parse(pa.text), balanceAmount: totalVal, monthlySavings: Value(CurrencyFormatter.parse(sonchoy.text)), startDate: DateTime.now(), endDate: DateTime.now().add(const Duration(days: 365)))); }
    else { await (db.update(db.loans)..where((t) => t.id.equals(existing.id))).write(LoansCompanion(name: Value(name.text.trim()), type: Value(type), totalAmount: Value(totalVal), monthlyPayment: Value(CurrencyFormatter.parse(pa.text)), monthlySavings: Value(CurrencyFormatter.parse(sonchoy.text)))); }
    if (ctx.mounted) Navigator.pop(ctx);
  }, child: const Text('Save'))])));
}
