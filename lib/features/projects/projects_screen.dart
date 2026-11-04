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
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Projects & Planning'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bazar Shop'),
              Tab(text: 'Home Build'),
              Tab(text: 'Goals'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BazarTab(),
            _HomeTab(),
            _GoalsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bazar Shop Plan — monthly grocery checklist with target vs actual cost.
// ---------------------------------------------------------------------------

class _BazarTab extends ConsumerWidget {
  const _BazarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final year = ref.watch(selectedYearProvider);
    final month = ref.watch(selectedMonthProvider);

    // NOTE: successive ..where() calls are AND-ed by Drift. We deliberately
    // chain them instead of using `&` on expressions: this file only imports
    // `Value` from drift, and the expression operators are not in scope here.
    final query = db.select(db.bazarShopItems)
      ..where((t) => t.year.equals(year))
      ..where((t) => t.month.equals(month));

    return StreamBuilder<List<BazarShopItem>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        final target = items.fold<double>(
          0,
          (sum, item) =>
              sum + FinanceCalculations.lineTotal(item.quantity, item.unitPrice),
        );
        final actual = items.fold<double>(
          0,
          (sum, item) => sum + item.actualCost,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Target ${CurrencyFormatter.bdt(target)} • '
                'Actual ${CurrencyFormatter.bdt(actual)} • '
                'Variance ${CurrencyFormatter.bdt(
                  FinanceCalculations.variance(target, actual),
                )}',
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return CheckboxListTile(
                    value: item.isChecked,
                    title: Text(
                      '${item.itemName} — ${item.quantity} ${item.unit} '
                      '× ${CurrencyFormatter.bdt(item.unitPrice)}',
                    ),
                    subtitle: Text(
                      'Target ${CurrencyFormatter.bdt(
                        FinanceCalculations.lineTotal(
                          item.quantity,
                          item.unitPrice,
                        ),
                      )} • Actual ${CurrencyFormatter.bdt(item.actualCost)}',
                    ),
                    onChanged: (value) async {
                      final update = db.update(db.bazarShopItems)
                        ..where((t) => t.id.equals(item.id));
                      await update.write(
                        BazarShopItemsCompanion(
                          isChecked: Value(value ?? false),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: () => _addBazarItem(context, ref),
              child: const Text('Add Bazar Item'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addBazarItem(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: 'Rice');
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final actualController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Bazar Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item'),
              ),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Unit Price (৳)'),
              ),
              TextField(
                controller: actualController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Actual Cost (৳)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final db = ref.read(appDatabaseProvider);
                await db.into(db.bazarShopItems).insert(
                      BazarShopItemsCompanion.insert(
                        year: ref.read(selectedYearProvider),
                        month: ref.read(selectedMonthProvider),
                        itemName: nameController.text.trim(),
                        quantity: Value(
                          CurrencyFormatter.parse(qtyController.text),
                        ),
                        unitPrice: Value(
                          CurrencyFormatter.parse(priceController.text),
                        ),
                        actualCost: Value(
                          CurrencyFormatter.parse(actualController.text),
                        ),
                      ),
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

    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    actualController.dispose();
  }
}

// ---------------------------------------------------------------------------
// Home Construction Estimator — materials cost, paid amount, remaining target.
// ---------------------------------------------------------------------------

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return StreamBuilder<List<HomeConstructionItem>>(
      stream: db.select(db.homeConstructionItems).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        final total = items.fold<double>(
          0,
          (sum, item) =>
              sum + FinanceCalculations.lineTotal(item.quantity, item.unitPrice),
        );
        final paid = items.fold<double>(
          0,
          (sum, item) => sum + item.paidAmount,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Total Budget ${CurrencyFormatter.bdt(total)} • '
                'Paid ${CurrencyFormatter.bdt(paid)} • '
                'Remaining Capital Target ${CurrencyFormatter.bdt(total - paid)}',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final estimated = FinanceCalculations.lineTotal(
                    item.quantity,
                    item.unitPrice,
                  );
                  return ListTile(
                    title: Text(
                      '${item.itemName} — ${item.quantity} ${item.unit} '
                      '× ${CurrencyFormatter.bdt(item.unitPrice)}',
                    ),
                    subtitle: Text(
                      'Estimated ${CurrencyFormatter.bdt(estimated)} • '
                      'Paid ${CurrencyFormatter.bdt(item.paidAmount)} • '
                      'Due ${CurrencyFormatter.bdt(estimated - item.paidAmount)}',
                    ),
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: () => _addConstructionItem(context, ref),
              child: const Text('Add Material / Cost'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addConstructionItem(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final paidController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Construction Cost'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item (Bricks, Cement, Rod...)',
                ),
              ),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Unit Price (৳)'),
              ),
              TextField(
                controller: paidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Paid Amount (৳)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final db = ref.read(appDatabaseProvider);
                await db.into(db.homeConstructionItems).insert(
                      HomeConstructionItemsCompanion.insert(
                        itemName: nameController.text.trim(),
                        quantity: Value(
                          CurrencyFormatter.parse(qtyController.text),
                        ),
                        unitPrice: Value(
                          CurrencyFormatter.parse(priceController.text),
                        ),
                        paidAmount: Value(
                          CurrencyFormatter.parse(paidController.text),
                        ),
                      ),
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

    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    paidController.dispose();
  }
}

// ---------------------------------------------------------------------------
// Future Goals — long-term savings milestones with progress.
// ---------------------------------------------------------------------------

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(futureGoalsProvider);

    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (goals) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final percent = FinanceCalculations.goalProgressPercent(
                    goal.targetAmount,
                    goal.savedAmount,
                  );
                  return Card(
                    child: ListTile(
                      title: Text(goal.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target ${CurrencyFormatter.bdt(goal.targetAmount)} • '
                            'Saved ${CurrencyFormatter.bdt(goal.savedAmount)} • '
                            'Remaining ${CurrencyFormatter.bdt(
                              goal.targetAmount - goal.savedAmount,
                            )}'
                            '${goal.deadline != null ? ' • Deadline ${goal.deadline!.toString().split(' ').first}' : ''}',
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: percent / 100),
                          Text('${percent.toStringAsFixed(1)}%'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: () => _addGoal(context, ref),
              child: const Text('Add Goal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final savedController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Future Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Land Purchase, Bank FD...)',
                ),
              ),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target (৳)'),
              ),
              TextField(
                controller: savedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saved So Far (৳)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final db = ref.read(appDatabaseProvider);
                await db.into(db.futureGoals).insert(
                      FutureGoalsCompanion.insert(
                        title: titleController.text.trim(),
                        targetAmount: CurrencyFormatter.parse(
                          targetController.text,
                        ),
                        savedAmount: Value(
                          CurrencyFormatter.parse(savedController.text),
                        ),
                        deadline: Value(
                          DateTime(DateTime.now().year + 3, 12, 31),
                        ),
                      ),
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

    titleController.dispose();
    targetController.dispose();
    savedController.dispose();
  }
}
