import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/finance_calculations.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/providers.dart';
import 'entry_form_dialog.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});
  @override ConsumerState<LedgerScreen> createState() => _State();
}
class _State extends ConsumerState<LedgerScreen> {
  bool showProjected = true;
  @override
  Widget build(BuildContext context) {
    final year = ref.watch(selectedYearProvider); final entriesAsync = ref.watch(ledgerEntriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Ledger'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => showEntryForm(context, ref, type: 'expense'))]),
      body: Column(children: [
        SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), children: AppConstants.years.map((y) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), child: ChoiceChip(label: Text('$y'), selected: y == year, onSelected: (_) => ref.read(selectedYearProvider.notifier).state = y))).toList())),
        SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), children: [for (var m = 1; m <= 12; m++) Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), child: ChoiceChip(label: Text(AppConstants.months[m - 1].substring(0, 3)), selected: m == ref.watch(selectedMonthProvider), onSelected: (_) => ref.read(selectedMonthProvider.notifier).state = m))])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Projected Budget')), ButtonSegment(value: false, label: Text('Actual Cost'))], selected: {showProjected}, onSelectionChanged: (s) => setState(() => showProjected = s.first))),
        Expanded(child: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (entries) {
            if (entries.isEmpty) return const EmptyState(message: 'No entries for this month. Add income or expenses to start.');
            double pI = 0, aI = 0, pE = 0, aE = 0;
            for (final e in entries) { if (e.type == 'income') { pI += e.projectedAmount; aI += e.actualAmount; } else { pE += e.projectedAmount; aE += e.actualAmount; } }
            return Column(children: [
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Income  ${CurrencyFormatter.bdt(aI)}  •  Expenses  ${CurrencyFormatter.bdt(aE)}  •  Net  ${CurrencyFormatter.bdt(FinanceCalculations.netSavings(aI, aE))}\nProjected Net ${CurrencyFormatter.bdt(pI - pE)}  •  Variance ${CurrencyFormatter.bdt(FinanceCalculations.variance(pI - pE, aI - aE))}', textAlign: TextAlign.center))),
              Expanded(child: ListView.builder(itemCount: entries.length, itemBuilder: (_, i) {
                final e = entries[i]; final v = FinanceCalculations.variance(e.projectedAmount, e.actualAmount);
                return ListTile(
                  leading: CircleAvatar(child: Icon(e.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward, size: 18)),
                  title: Text(e.category), subtitle: Text('Projected ${CurrencyFormatter.bdt(e.projectedAmount)} • Actual ${CurrencyFormatter.bdt(e.actualAmount)}\nVariance: ${CurrencyFormatter.bdt(v)}${e.title.isEmpty ? '' : ' • ${e.title}'}'),
                  trailing: Text(CurrencyFormatter.bdt(showProjected ? e.projectedAmount : e.actualAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => showEntryForm(context, ref, type: e.type, existing: e),
                  onLongPress: () async { final db = ref.read(appDatabaseProvider); await (db.delete(db.ledgerEntries)..where((t) => t.id.equals(e.id))).go(); },
                );
              })),
            ]);
          })),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => showEntryForm(context, ref, type: 'income'), child: const Icon(Icons.add)),
    );
  }
}
