import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/summary_card.dart';
import '../../data/providers.dart';
import '../ledger/entry_form_dialog.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(ledgerEntriesProvider);
    final loansAsync = ref.watch(allLoansProvider);
    final year = ref.watch(selectedYearProvider); final month = ref.watch(selectedMonthProvider);
    final outstanding = loansAsync.valueOrNull?.where((l) => l.isActive).fold<double>(0, (s, l) => s + l.balanceAmount) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.payments_outlined), tooltip: 'Salary & PF', onPressed: () => context.push('/salary-pf')),
        IconButton(icon: const Icon(Icons.cloud_outlined), tooltip: 'Backup & Settings', onPressed: () => context.push('/backup')),
      ]),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          final s = MonthlySummary.fromEntries(entries);
          final cats = s.expenseByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return ListView(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Row(children: [
              Expanded(child: Text('${AppConstants.months[month - 1]} $year', style: Theme.of(context).textTheme.titleLarge)),
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shift(ref, -1)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shift(ref, 1)),
            ])),
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.55, children: [
              SummaryCard(title: 'Total Income', amount: s.income, icon: Icons.arrow_downward, color: Colors.green),
              SummaryCard(title: 'Total Expenses', amount: s.expense, icon: Icons.arrow_upward, color: Colors.red),
              SummaryCard(title: 'Net Savings', amount: s.netSavings, icon: Icons.savings_outlined, color: Colors.teal),
              SummaryCard(title: 'Loan Outstanding', amount: outstanding, icon: Icons.credit_card, color: Colors.orange),
            ]),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium)),
            Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Add Income'), onPressed: () => showEntryForm(context, ref, type: 'income')),
              ActionChip(avatar: const Icon(Icons.remove, size: 18), label: const Text('Add Expense'), onPressed: () => showEntryForm(context, ref, type: 'expense')),
              ActionChip(avatar: const Icon(Icons.credit_card, size: 18), label: const Text('Record EMI'), onPressed: () => context.go('/loans')),
              ActionChip(avatar: const Icon(Icons.cloud_upload, size: 18), label: const Text('Backup to Drive'), onPressed: () => context.push('/backup')),
            ])),
            if (cats.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Expense by Category (Bar)', style: Theme.of(context).textTheme.titleMedium)),
              SizedBox(height: 220, child: Padding(padding: const EdgeInsets.all(16), child: BarChart(BarChartData(barGroups: [for (var i = 0; i < cats.length && i < 7; i++) BarChartGroupData(x: i, barRods: [BarChartRodData(toY: cats[i].value, width: 18, color: Theme.of(context).colorScheme.primary)])], titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(v.toInt() < cats.length ? cats[v.toInt()].key.split(' ').first : '', style: const TextStyle(fontSize: 9)))), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))))))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Expense Share (Pie)', style: Theme.of(context).textTheme.titleMedium)),
              SizedBox(height: 220, child: PieChart(PieChartData(sections: [for (var i = 0; i < cats.length; i++) PieChartSectionData(value: cats[i].value, title: s.expense == 0 ? '' : '${(cats[i].value / s.expense * 100).toStringAsFixed(0)}%', color: Colors.primaries[i % Colors.primaries.length], radius: 70)]))),
              ...cats.map((c) => ListTile(dense: true, title: Text(c.key), trailing: Text(CurrencyFormatter.bdt(c.value)))),
            ] else const Padding(padding: EdgeInsets.all(24), child: Text('No expenses this month yet. Tap + to add one.')),
          ]);
        }),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showEntryForm(context, ref, type: 'expense'), icon: const Icon(Icons.add), label: const Text('Add Entry')),
    );
  }
  void _shift(WidgetRef ref, int delta) {
    var m = ref.read(selectedMonthProvider) + delta; var y = ref.read(selectedYearProvider);
    if (m < 1) { m = 12; y--; } if (m > 12) { m = 1; y++; }
    ref.read(selectedMonthProvider.notifier).state = m; ref.read(selectedYearProvider.notifier).state = y;
  }
}
