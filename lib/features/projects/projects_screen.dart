import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/finance_calculations.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(length: 3, child: Scaffold(appBar: AppBar(title: const Text('Projects & Planning'), bottom: const TabBar(tabs: [Tab(text: 'Bazar Shop'), Tab(text: 'Home Build'), Tab(text: 'Goals')])), body: const TabBarView(children: [_BazarTab(), _HomeTab(), _GoalsTab()]))));
}

class _BazarTab extends ConsumerWidget { const _BazarTab();
  @override Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider); final y = ref.watch(selectedYearProvider); final m = ref.watch(selectedMonthProvider);
    final stream = (db.select(db.bazarShopItems)..where((t) => t.year.equals(y) & t.month.equals(m))).watch();
    return StreamBuilder(stream: stream, builder: (_, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final items = snap.data!; final target = items.fold<double>(0, (s, i) => s + FinanceCalculations.lineTotal(i.quantity, i.unitPrice)); final actual = items.fold<double>(0, (s, i) => s + i.actualCost);
      return Column(children: [Padding(padding: const EdgeInsets.all(12), child: Text('Target ${CurrencyFormatter.bdt(target)} • Actual ${CurrencyFormatter.bdt(actual)} • Variance ${CurrencyFormatter.bdt(FinanceCalculations.variance(target, actual))}')), Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (_, i) { final it = items[i]; return CheckboxListTile(value: it.isChecked, onChanged: (v) async => (db.update(db.bazarShopItems)..where((t) => t.id.equals(it.id))).write(BazarShopItemsCompanion(isChecked: Value(v ?? false))), title: Text('${it.itemName} — ${it.quantity} ${it.unit} × ${CurrencyFormatter.bdt(it.unitPrice)}'), subtitle: Text('Target ${CurrencyFormatter.bdt(FinanceCalculations.lineTotal(it.quantity, it.unitPrice))} • Actual ${CurrencyFormatter.bdt(it.actualCost)}')); })), FilledButton(onPressed: () => _add(context, ref), child: const Text('Add Bazar Item'))]);
    });
  }
  Future<void> _add(BuildContext context, WidgetRef ref) async { final name = TextEditingController(text: 'Rice'); final qty = TextEditingController(text: '1'); final price = TextEditingController(); final act = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add Bazar Item'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Item')), TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')), TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Price (৳)')), TextField(controller: act, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual Cost (৳)'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { final db = ref.read(appDatabaseProvider); await db.into(db.bazarShopItems).insert(BazarShopItemsCompanion.insert(year: ref.read(selectedYearProvider), month: ref.read(selectedMonthProvider), itemName: name.text.trim(), quantity: Value(CurrencyFormatter.parse(qty.text)), unitPrice: Value(CurrencyFormatter.parse(price.text)), actualCost: Value(CurrencyFormatter.parse(act.text)))); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Save'))])); }
}

class _HomeTab extends ConsumerWidget { const _HomeTab();
  @override Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    return StreamBuilder(stream: db.select(db.homeConstructionItems).watch(), builder: (_, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final items = snap.data!; final total = items.fold<double>(0, (s, i) => s + FinanceCalculations.lineTotal(i.quantity, i.unitPrice)); final paid = items.fold<double>(0, (s, i) => s + i.paidAmount);
      return Column(children: [Padding(padding: const EdgeInsets.all(12), child: Text('Total Budget ${CurrencyFormatter.bdt(total)} • Paid ${CurrencyFormatter.bdt(paid)} • Remaining Capital Target ${CurrencyFormatter.bdt(total - paid)}', textAlign: TextAlign.center)), Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (_, i) { final it = items[i]; final est = FinanceCalculations.lineTotal(it.quantity, it.unitPrice); return ListTile(title: Text('${it.itemName} — ${it.quantity} ${it.unit} × ${CurrencyFormatter.bdt(it.unitPrice)}'), subtitle: Text('Estimated ${CurrencyFormatter.bdt(est)} • Paid ${CurrencyFormatter.bdt(it.paidAmount)} • Due ${CurrencyFormatter.bdt(est - it.paidAmount)}')); })), FilledButton(onPressed: () => _add(context, ref), child: const Text('Add Material / Cost'))]);
    });
  }
  Future<void> _add(BuildContext context, WidgetRef ref) async { final name = TextEditingController(); final qty = TextEditingController(text: '1'); final price = TextEditingController(); final paid = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add Construction Cost'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Item (Bricks, Cement, Rod...)')), TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')), TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Price (৳)')), TextField(controller: paid, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Paid Amount (৳)'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { final db = ref.read(appDatabaseProvider); await db.into(db.homeConstructionItems).insert(HomeConstructionItemsCompanion.insert(itemName: name.text.trim(), quantity: Value(CurrencyFormatter.parse(qty.text)), unitPrice: Value(CurrencyFormatter.parse(price.text)), paidAmount: Value(CurrencyFormatter.parse(paid.text)))); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Save'))])); }
}

class _GoalsTab extends ConsumerWidget { const _GoalsTab();
  @override Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(futureGoalsProvider);
    return goalsAsync.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('Error: $e')), data: (goals) => Column(children: [Expanded(child: ListView.builder(itemCount: goals.length, itemBuilder: (_, i) { final g = goals[i]; final pct = FinanceCalculations.goalProgressPercent(g.targetAmount, g.savedAmount); return Card(child: ListTile(title: Text(g.title), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Target ${CurrencyFormatter.bdt(g.targetAmount)} • Saved ${CurrencyFormatter.bdt(g.savedAmount)} • Remaining ${CurrencyFormatter.bdt(g.targetAmount - g.savedAmount)}${g.deadline != null ? ' • Deadline ${g.deadline!.toString().split(' ').first}' : ''}'), const SizedBox(height: 6), LinearProgressIndicator(value: pct / 100), Text('${pct.toStringAsFixed(1)}%')]))); })), FilledButton(onPressed: () => _add(context, ref), child: const Text('Add Goal'))]));
  }
  Future<void> _add(BuildContext context, WidgetRef ref) async { final title = TextEditingController(); final target = TextEditingController(); final saved = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add Future Goal'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'Title (Land Purchase, Bank FD...)')), TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target (৳)')), TextField(controller: saved, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Saved So Far (৳)'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { final db = ref.read(appDatabaseProvider); await db.into(db.futureGoals).insert(FutureGoalsCompanion.insert(title: title.text.trim(), targetAmount: CurrencyFormatter.parse(target.text), savedAmount: Value(CurrencyFormatter.parse(saved.text)), deadline: Value(DateTime(DateTime.now().year + 3, 12, 31)))); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Save'))])); }
}
