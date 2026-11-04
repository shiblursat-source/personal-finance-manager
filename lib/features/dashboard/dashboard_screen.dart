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
    final year = ref.watch(selectedYearProvider);
    final month = ref.watch(selectedMonthProvider);

    final outstanding = loansAsync.valueOrNull
            ?.where((loan) => loan.isActive)
            .fold<double>(0, (sum, loan) => sum + loan.balanceAmount) ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: 'Salary & PF',
            onPressed: () => context.push('/salary-pf'),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_outlined),
            tooltip: 'Backup & Settings',
            onPressed: () => context.push('/backup'),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (entries) {
          final summary = MonthlySummary.fromEntries(entries);
          final categories = summary.expenseByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            children: [
              _buildMonthHeader(context, ref, year, month),
              _buildSummaryGrid(summary, outstanding),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _buildQuickActions(context, ref),
              if (categories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Expense by Category (Bar)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _buildBarChart(context, categories),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Expense Share (Pie)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _buildPieChart(summary, categories),
                ...categories.map(
                  (category) => ListTile(
                    dense: true,
                    title: Text(category.key),
                    trailing: Text(CurrencyFormatter.bdt(category.value)),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No expenses this month yet. Tap + to add one.'),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEntryForm(context, ref, type: 'expense'),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildMonthHeader(
    BuildContext context,
    WidgetRef ref,
    int year,
    int month,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${AppConstants.months[month - 1]} $year',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shiftMonth(ref, -1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shiftMonth(ref, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(MonthlySummary summary, double outstanding) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        SummaryCard(
          title: 'Total Income',
          amount: summary.income,
          icon: Icons.arrow_downward,
          color: Colors.green,
        ),
        SummaryCard(
          title: 'Total Expenses',
          amount: summary.expense,
          icon: Icons.arrow_upward,
          color: Colors.red,
        ),
        SummaryCard(
          title: 'Net Savings',
          amount: summary.netSavings,
          icon: Icons.savings_outlined,
          color: Colors.teal,
        ),
        SummaryCard(
          title: 'Loan Outstanding',
          amount: outstanding,
          icon: Icons.credit_card,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Add Income'),
            onPressed: () => showEntryForm(context, ref, type: 'income'),
          ),
          ActionChip(
            avatar: const Icon(Icons.remove, size: 18),
            label: const Text('Add Expense'),
            onPressed: () => showEntryForm(context, ref, type: 'expense'),
          ),
          ActionChip(
            avatar: const Icon(Icons.credit_card, size: 18),
            label: const Text('Record EMI'),
            onPressed: () => context.go('/loans'),
          ),
          ActionChip(
            avatar: const Icon(Icons.cloud_upload, size: 18),
            label: const Text('Backup to Drive'),
            onPressed: () => context.push('/backup'),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    List<MapEntry<String, double>> categories,
  ) {
    final shownCount = categories.length > 7 ? 7 : categories.length;
    final groups = <BarChartGroupData>[
      for (var i = 0; i < shownCount; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: categories[i].value,
              width: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
    ];

    final bottomTitles = AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        getTitlesWidget: (double value, TitleMeta meta) {
          final index = value.toInt();
          final label = index < categories.length
              ? categories[index].key.split(' ').first
              : '';
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(label, style: const TextStyle(fontSize: 9)),
          );
        },
      ),
    );

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            barGroups: groups,
            titlesData: FlTitlesData(
              bottomTitles: bottomTitles,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(
    MonthlySummary summary,
    List<MapEntry<String, double>> categories,
  ) {
    final sections = <PieChartSectionData>[
      for (var i = 0; i < categories.length; i++)
        PieChartSectionData(
          value: categories[i].value,
          title: summary.expense == 0
              ? ''
              : '${(categories[i].value / summary.expense * 100).toStringAsFixed(0)}%',
          color: Colors.primaries[i % Colors.primaries.length],
          radius: 70,
        ),
    ];

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(sections: sections),
      ),
    );
  }

  void _shiftMonth(WidgetRef ref, int delta) {
    var month = ref.read(selectedMonthProvider) + delta;
    var year = ref.read(selectedYearProvider);
    if (month < 1) {
      month = 12;
      year--;
    }
    if (month > 12) {
      month = 1;
      year++;
    }
    ref.read(selectedMonthProvider.notifier).state = month;
    ref.read(selectedYearProvider.notifier).state = year;
  }
}
