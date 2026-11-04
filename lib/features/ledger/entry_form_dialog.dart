import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

Future<void> showEntryForm(BuildContext context, WidgetRef ref, {required String type, LedgerEntry? existing}) async {
  final cats = type == 'income' ? AppConstants.incomeCategories : AppConstants.expenseCategories;
  var category = existing?.category ?? cats.first;
  final title = TextEditingController(text: existing?.title ?? '');
  final projected = TextEditingController(text: existing != null ? existing.projectedAmount.toStringAsFixed(0) : '');
  final actual = TextEditingController(text: existing != null ? existing.actualAmount.toStringAsFixed(0) : '');
  await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text('${existing == null ? 'Add' : 'Edit'} ${type == 'income' ? 'Income' : 'Expense'}'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(value: cats.contains(category) ? category : cats.first, decoration: const InputDecoration(labelText: 'Category'), items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() => category = v ?? cats.first)),
      const SizedBox(height: 12),
      TextField(controller: title, decoration: const InputDecoration(labelText: 'Title (optional)')),
      const SizedBox(height: 12),
      TextField(controller: projected, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Projected Budget (৳)')),
      const SizedBox(height: 12),
      TextField(controller: actual, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual (৳)')),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      FilledButton(onPressed: () async {
        final db = ref.read(appDatabaseProvider);
        final comp = LedgerEntriesCompanion(year: Value(ref.read(selectedYearProvider)), month: Value(ref.read(selectedMonthProvider)), type: Value(type), category: Value(category), title: Value(title.text.trim()), projectedAmount: Value(CurrencyFormatter.parse(projected.text)), actualAmount: Value(CurrencyFormatter.parse(actual.text)));
        if (existing == null) {
          await db.into(db.ledgerEntries).insert(LedgerEntriesCompanion.insert(year: ref.read(selectedYearProvider), month: ref.read(selectedMonthProvider), type: type, category: category, title: Value(title.text.trim()), projectedAmount: Value(CurrencyFormatter.parse(projected.text)), actualAmount: Value(CurrencyFormatter.parse(actual.text))));
        } else {
          await (db.update(db.ledgerEntries)..where((t) => t.id.equals(existing.id))).write(comp);
        }
        if (ctx.mounted) Navigator.pop(ctx);
      }, child: const Text('Save')),
    ]))));
}
