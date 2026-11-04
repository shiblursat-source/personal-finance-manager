import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/finance_calculations.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

class OccasionsScreen extends ConsumerWidget {
  const OccasionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(length: 2, child: Scaffold(
    appBar: AppBar(title: const Text('Occasions & Events'), bottom: const TabBar(tabs: [Tab(text: 'Eid Budget'), Tab(text: 'Tour & Travel')])),
    body: TabBarView(children: [_OccasionList(type: 'eid'), _OccasionList(type: 'tour')]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _addBudget(context, ref), icon: const Icon(Icons.add), label: const Text('New Budget')),
  ));
  Future<void> _addBudget(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController(); final income = TextEditingController(); var type = 'eid';
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(title: const Text('New Occasion Budget'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(value: type, items: const [DropdownMenuItem(value: 'eid', child: Text('Eid')), DropdownMenuItem(value: 'tour', child: Text('Tour'))], onChanged: (v) => setState(() => type = v ?? 'eid'), decoration: const InputDecoration(labelText: 'Type')),
      TextField(controller: title, decoration: const InputDecoration(labelText: 'Title (e.g. Eid-ul-Adha / Cox\'s Bazar Tour)')),
      TextField(controller: income, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bonus / Fund Income (৳)')),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { final db = ref.read(appDatabaseProvider); await db.into(db.occasionBudgets).insert(OccasionBudgetsCompanion.insert(type: type, title: title.text.trim().isEmpty ? (type == 'eid' ? 'Eid Budget' : 'Tour') : title.text.trim(), year: ref.read(selectedYearProvider), incomeBudget: Value(CurrencyFormatter.parse(income.text)))); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Save'))])));
  }
}

class _OccasionList extends ConsumerWidget {
  const _OccasionList({required this.type}); final String type;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(occasionBudgetsProvider); final itemsAsync = ref.watch(occasionItemsProvider);
    return budgetsAsync.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('Error: $e')), data: (budgets) {
      final filtered = budgets.where((b) => b.type == type).toList();
      if (filtered.isEmpty) return EmptyState(message: type == 'eid' ? 'No Eid budget yet.' : 'No tour plan yet.');
      final items = itemsAsync.valueOrNull ?? [];
      return ListView(children: filtered.map((b) {
        final its = items.where((i) => i.budgetId == b.id).toList();
        final budgeted = its.fold<double>(0, (s, i) => s + i.budgetedAmount); final actual = its.fold<double>(0, (s, i) => s + i.actualAmount);
        return ExpansionTile(title: Text(b.title), subtitle: Text('Fund/Bonus ${CurrencyFormatter.bdt(b.incomeBudget)} • Budget ${CurrencyFormatter.bdt(budgeted)} • Actual ${CurrencyFormatter.bdt(actual)} • Variance ${CurrencyFormatter.bdt(FinanceCalculations.variance(budgeted, actual))} • vs Income ${CurrencyFormatter.bdt(b.incomeBudget - actual)}'), children: [
          ...its.map((i) => ListTile(title: Text(i.personOrCategory), subtitle: Text('Budget ${CurrencyFormatter.bdt(i.budgetedAmount)} • Actual ${CurrencyFormatter.bdt(i.actualAmount)} • Variance ${CurrencyFormatter.bdt(FinanceCalculations.variance(i.budgetedAmount, i.actualAmount))}'), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { final db = ref.read(appDatabaseProvider); await (db.delete(db.occasionItems)..where((t) => t.id.equals(i.id))).go(); }))),
          TextButton.icon(onPressed: () => _addItem(context, ref, b.id, type), icon: const Icon(Icons.add), label: const Text('Add Item / Person')),
        ]);
      }).toList());
    });
  }
  Future<void> _addItem(BuildContext context, WidgetRef ref, int budgetId, String type) async {
    final suggestions = type == 'eid' ? ['Abba','Maa','Bou','Omor','Ramim','Eid Bazar','Eid Transport'] : ['Bus Rent','Hotel Accommodation','Food','Sightseeing','Miscellaneous'];
    var person = suggestions.first; final bud = TextEditingController(); final act = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(title: const Text('Add Item'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(value: person, items: suggestions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => person = v ?? suggestions.first), decoration: const InputDecoration(labelText: 'Person / Category')),
      TextField(controller: bud, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Budgeted (৳)')),
      TextField(controller: act, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual (৳)')),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { final db = ref.read(appDatabaseProvider); await db.into(db.occasionItems).insert(OccasionItemsCompanion.insert(budgetId: budgetId, personOrCategory: person, budgetedAmount: Value(CurrencyFormatter.parse(bud.text)), actualAmount: Value(CurrencyFormatter.parse(act.text)))); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Save'))])));
  }
}
