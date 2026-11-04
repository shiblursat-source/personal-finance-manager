import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

/// Shows the Add/Edit dialog for one ledger entry.
///
/// [type] is 'income' or 'expense'. When [existing] is given the dialog
/// edits that entry, otherwise it creates a new one for the currently
/// selected year/month.
Future<void> showEntryForm(
  BuildContext context,
  WidgetRef ref, {
  required String type,
  LedgerEntry? existing,
}) async {
  final categories = type == 'income'
      ? AppConstants.incomeCategories
      : AppConstants.expenseCategories;
  var category = existing?.category ?? categories.first;
  if (!categories.contains(category)) {
    category = categories.first;
  }

  final titleController = TextEditingController(text: existing?.title ?? '');
  final projectedController = TextEditingController(
    text: existing != null ? existing.projectedAmount.toStringAsFixed(0) : '',
  );
  final actualController = TextEditingController(
    text: existing != null ? existing.actualAmount.toStringAsFixed(0) : '',
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(
              '${existing == null ? 'Add' : 'Edit'} '
              '${type == 'income' ? 'Income' : 'Expense'}',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => category = value ?? categories.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: projectedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Projected Budget (৳)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: actualController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Actual (৳)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  await _saveEntry(
                    ref,
                    type: type,
                    category: category,
                    title: titleController.text.trim(),
                    projectedAmount: CurrencyFormatter.parse(
                      projectedController.text,
                    ),
                    actualAmount: CurrencyFormatter.parse(
                      actualController.text,
                    ),
                    existing: existing,
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  titleController.dispose();
  projectedController.dispose();
  actualController.dispose();
}

Future<void> _saveEntry(
  WidgetRef ref, {
  required String type,
  required String category,
  required String title,
  required double projectedAmount,
  required double actualAmount,
  LedgerEntry? existing,
}) async {
  final db = ref.read(appDatabaseProvider);
  final year = ref.read(selectedYearProvider);
  final month = ref.read(selectedMonthProvider);

  if (existing == null) {
    await db.into(db.ledgerEntries).insert(
          LedgerEntriesCompanion.insert(
            year: year,
            month: month,
            type: type,
            category: category,
            title: Value(title),
            projectedAmount: Value(projectedAmount),
            actualAmount: Value(actualAmount),
          ),
        );
  } else {
    final companion = LedgerEntriesCompanion(
      year: Value(year),
      month: Value(month),
      type: Value(type),
      category: Value(category),
      title: Value(title),
      projectedAmount: Value(projectedAmount),
      actualAmount: Value(actualAmount),
    );
    await (db.update(db.ledgerEntries)
          ..where((t) => t.id.equals(existing.id)))
        .write(companion);
  }
}
