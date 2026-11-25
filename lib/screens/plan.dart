import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets/category_dialog.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).typography;
        final cur = store.currency;
        final spentByCat = store.byCategory(TxType.expense, DateTime(DateTime.now().year, DateTime.now().month));
        final spentTotal = store.total(TxType.expense, DateTime(DateTime.now().year, DateTime.now().month));
        final expenseCats = store.cats.where((c) => c.type == TxType.expense).toList();
        final incomeCats = store.cats.where((c) => c.type == TxType.income).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Plan', style: tt.x3Large.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Card(
              child: GestureDetector(
                onTap: () async {
                  final v = await askNumber(
                    context,
                    title: 'Monthly budget',
                    initial: store.monthlyBudget,
                  );
                  if (v != null) store.setBudget(v);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly budget'),
                            const SizedBox(height: 4),
                            Text(
                              store.monthlyBudget > 0
                                  ? '${money(spentTotal, cur)} spent this month'
                                  : 'Not set',
                              style: Theme.of(context).typography.small,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        store.monthlyBudget > 0 ? money(store.monthlyBudget, cur) : 'Set',
                        style: tt.large.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Category limits',
              onAdd: () => showCategoryDialog(context, type: TxType.expense),
            ),
            for (final c in expenseCats)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryCard(cat: c, spent: spentByCat[c.id] ?? 0),
              ),
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Income categories',
              onAdd: () => showCategoryDialog(context, type: TxType.income),
            ),
            for (final c in incomeCats)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryCard(cat: c, spent: 0),
              ),
            const SizedBox(height: 16),
            Text('Recurring', style: tt.large),
            const SizedBox(height: 8),
            if (store.recurring.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nothing recurring. When you add a transaction, choose Weekly or Monthly '
                    'and it will be logged for you automatically.',
                    style: tt.base.copyWith(color: cs.mutedForeground),
                  ),
                ),
              )
            else
              for (final r in store.recurring)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: store.cat(r.categoryId).colorValue.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: HugeIcon(
                                icon: store.cat(r.categoryId).iconData,
                                color: store.cat(r.categoryId).colorValue,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.note.isEmpty ? store.cat(r.categoryId).name : r.note),
                                Text(
                                  '${money(r.amount, cur)} · ${r.repeat == Repeat.weekly ? 'Weekly' : 'Monthly'}'
                                  ' · next ${DateFormat('d MMM').format(r.next)}',
                                  style: Theme.of(context).typography.small,
                                ),
                              ],
                            ),
                          ),
                          Button.ghost(
                            onPressed: () async {
                              if (await confirm(context, 'Stop recurring?',
                                  'Past transactions stay. No new ones will be added.')) {
                                store.deleteRecurring(r.id);
                              }
                            },
                            child: const HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).typography.large)),
          Button.ghost(
            onPressed: onAdd,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18),
                SizedBox(width: 4),
                Text('Add'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category cat;
  final double spent;
  const _CategoryCard({required this.cat, required this.spent});

  @override
  Widget build(BuildContext context) {
    final isExpense = cat.type == TxType.expense;
    final hasLimit = isExpense && cat.budget > 0;
    final ratio = hasLimit ? spent / cat.budget : 0.0;

    return Card(
      child: GestureDetector(
        onTap: isExpense
            ? () async {
                final v = await askNumber(
                  context,
                  title: '${cat.name} monthly limit',
                  initial: cat.budget,
                  hint: '0 for no limit',
                );
                if (v != null) {
                  cat.budget = v;
                  store.saveCategory(cat);
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.colorValue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: HugeIcon(icon: cat.iconData, color: cat.colorValue, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isExpense) ...[
                      const SizedBox(height: 2),
                      Text(
                        hasLimit
                            ? '${money(spent, store.currency)} of ${money(cat.budget, store.currency)}'
                            : spent > 0
                                ? '${money(spent, store.currency)} spent, no limit'
                                : 'No limit. Tap to set',
                        style: Theme.of(context).typography.small,
                      ),
                    ],
                    if (hasLimit) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0).toDouble(),
                      ),
                    ],
                  ],
                ),
              ),
              Button.ghost(
                onPressed: () async {
                  showDropdown<String>(
                    context: context,
                    builder: (context) => DropdownMenu(
                      children: [
                        MenuButton(
                          onPressed: (ctx) async {
                            await showCategoryDialog(ctx, type: cat.type, edit: cat);
                          },
                          child: const Text('Edit'),
                        ),
                        MenuButton(
                          onPressed: (ctx) async {
                            if (await confirm(ctx, 'Delete ${cat.name}?',
                                'Existing transactions will show as Uncategorized.')) {
                              store.deleteCategory(cat.id);
                            }
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                child: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
