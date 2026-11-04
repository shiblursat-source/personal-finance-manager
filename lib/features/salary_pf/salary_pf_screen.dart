import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/finance_calculations.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

class SalaryPfScreen extends ConsumerStatefulWidget { const SalaryPfScreen({super.key}); @override ConsumerState<SalaryPfScreen> createState() => _S(); }
class _S extends ConsumerState<SalaryPfScreen> {
  final basic = TextEditingController(text: '50000'); final hra = TextEditingController(text: '25000'); final med = TextEditingController(text: '5000'); final trans = TextEditingController(text: '5000');
  double _v(TextEditingController c) => CurrencyFormatter.parse(c.text);
  @override void dispose() { basic.dispose(); hra.dispose(); med.dispose(); trans.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final pfAsync = ref.watch(pfListProvider); final pfLoansAsync = ref.watch(pfLoansProvider);
    final gross = FinanceCalculations.grossSalary(basic: _v(basic), houseRent: _v(hra), medical: _v(med), transport: _v(trans));
    return Scaffold(appBar: AppBar(title: const Text('Salary & Provident Fund')), body: ListView(padding: const EdgeInsets.all(16), children: [
      Text('Salary Breakdown Calculator', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      _field(basic, 'Basic Salary (৳)'), _field(hra, 'House Rent Allowance (৳)'), _field(med, 'Medical Allowance (৳)'), _field(trans, 'Transport Allowance (৳)'),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Gross Total: ${CurrencyFormatter.bdt(gross)}', style: Theme.of(context).textTheme.titleMedium))),
      FilledButton(onPressed: () async { final db = ref.read(appDatabaseProvider); await db.into(db.salaryStructures).insert(SalaryStructuresCompanion.insert(year: ref.read(selectedYearProvider), month: ref.read(selectedMonthProvider), basicSalary: Value(_v(basic)), houseRentAllowance: Value(_v(hra)), medicalAllowance: Value(_v(med)), transportAllowance: Value(_v(trans)))); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary structure saved'))); }, child: const Text('Save Salary Structure')),
      const Divider(height: 32), Text('PF Ledger', style: Theme.of(context).textTheme.titleLarge),
      pfAsync.when(loading: () => const CircularProgressIndicator(), error: (e, _) => Text('Error: $e'), data: (list) {
        final latest = list.isEmpty ? null : list.first; final totalDeduction = list.fold<double>(0, (s, e) => s + e.monthlyDeduction);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cumulative PF Balance: ${CurrencyFormatter.bdt(latest?.cumulativeBalance ?? 0)}'),
          Text('Total Monthly Deductions Recorded: ${CurrencyFormatter.bdt(totalDeduction)}'),
          ...list.map((e) => ListTile(title: Text('${e.year}-${e.month.toString().padLeft(2, '0')} — Deduction ${CurrencyFormatter.bdt(e.monthlyDeduction)}'), subtitle: Text('Employer ${CurrencyFormatter.bdt(e.employerContribution)} • Balance ${CurrencyFormatter.bdt(e.cumulativeBalance)}'))),
        ]);
      }),
      FilledButton.tonal(onPressed: () => _addPf(context), child: const Text('Add PF Entry')),
      const Divider(height: 32), Text('PF Loan Repayment', style: Theme.of(context).textTheme.titleLarge),
      pfLoansAsync.when(loading: () => const CircularProgressIndicator(), error: (e, _) => Text('Error: $e'), data: (list) => Column(children: list.map((l) => ListTile(title: Text('PF Loan ${CurrencyFormatter.bdt(l.totalLoanAmount)}'), subtitle: Text('Monthly repayment ${CurrencyFormatter.bdt(l.monthlyRepayment)} • Paid ${CurrencyFormatter.bdt(l.paidAmount)} • Remaining ${CurrencyFormatter.bdt(l.totalLoanAmount - l.paidAmount)}'))).toList())),
      FilledButton.tonal(onPressed: () => _addPfLoan(context), child: const Text('Add PF Loan')),
    ]));
  }
  Widget _field(TextEditingController c, String label) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label), onChanged: (_) => setState(() {})));
  Future<void> _addPf(BuildContext context) async {
    final ded = TextEditingController(); final emp = TextEditingController(); final bal = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add PF Entry'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: ded, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Deduction (৳)')), TextField(controller: emp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Employer Contribution (৳)')), TextField(controller: bal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cumulative Balance (৳)'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { final db = ref.read(appDatabaseProvider); await db.into(db.pfEntries).insert(PfEntriesCompanion.insert(year: ref.read(selectedYearProvider), month: ref.read(selectedMonthProvider), monthlyDeduction: Value(CurrencyFormatter.parse(ded.text)), employerContribution: Value(CurrencyFormatter.parse(emp.text)), cumulativeBalance: Value(CurrencyFormatter.parse(bal.text)))); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Save'))]));
  }
  Future<void> _addPfLoan(BuildContext context) async {
    final total = TextEditingController(); final monthly = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add PF Loan'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: total, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total PF Loan (৳)')), TextField(controller: monthly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Repayment (৳)'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { final db = ref.read(appDatabaseProvider); await db.into(db.pfLoanEntries).insert(PfLoanEntriesCompanion.insert(totalLoanAmount: CurrencyFormatter.parse(total.text), monthlyRepayment: CurrencyFormatter.parse(monthly.text), startDate: DateTime.now())); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Save'))]));
  }
}
