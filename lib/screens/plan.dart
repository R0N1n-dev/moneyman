import 'package:material_ui/material_ui.dart';
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
        final tt = Theme.of(context).textTheme;
        final cur = store.currency;
        final spentByCat = store.byCategory(TxType.expense, DateTime(DateTime.now().year, DateTime.now().month));
        final spentTotal = store.total(TxType.expense, DateTime(DateTime.now().year, DateTime.now().month));
        final expenseCats = store.cats.where((c) => c.type == TxType.expense).toList();
        final incomeCats = store.cats.where((c) => c.type == TxType.income).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Plan', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: const Text('Monthly budget'),
                subtitle: Text(
                  store.monthlyBudget > 0
                      ? '${money(spentTotal, cur)} spent this month'
                      : 'Not set',
                ),
                trailing: Text(
                  store.monthlyBudget > 0 ? money(store.monthlyBudget, cur) : 'Set',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
                ),
                onTap: () async {
                  final v = await askNumber(
                    context,
                    title: 'Monthly budget',
                    initial: store.monthlyBudget,
                  );
                  if (v != null) store.setBudget(v);
                },
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
            Text('Recurring', style: tt.titleMedium),
            const SizedBox(height: 8),
            if (store.recurring.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nothing recurring. When you add a transaction, choose Weekly or Monthly '
                    'and it will be logged for you automatically.',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else
              for (final r in store.recurring)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: store.cat(r.categoryId).colorValue.withValues(alpha: 0.18),
                        child: Icon(
                          store.cat(r.categoryId).iconData,
                          color: store.cat(r.categoryId).colorValue,
                        ),
                      ),
                      title: Text(r.note.isEmpty ? store.cat(r.categoryId).name : r.note),
                      subtitle: Text(
                        '${money(r.amount, cur)} \u00b7 ${r.repeat == Repeat.weekly ? 'Weekly' : 'Monthly'}'
                        ' \u00b7 next ${DateFormat('d MMM').format(r.next)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await confirm(context, 'Stop recurring?',
                              'Past transactions stay. No new ones will be added.')) {
                            store.deleteRecurring(r.id);
                          }
                        },
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
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
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
    final cs = Theme.of(context).colorScheme;
    final isExpense = cat.type == TxType.expense;
    final hasLimit = isExpense && cat.budget > 0;
    final ratio = hasLimit ? spent / cat.budget : 0.0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
              CircleAvatar(
                backgroundColor: cat.colorValue.withValues(alpha: 0.18),
                child: Icon(cat.iconData, color: cat.colorValue),
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
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (hasLimit) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0).toDouble(),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                        color: ratio >= 1
                            ? cs.error
                            : ratio >= 0.8
                                ? Colors.orange
                                : cat.colorValue,
                        backgroundColor: cat.colorValue.withValues(alpha: 0.15),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    await showCategoryDialog(context, type: cat.type, edit: cat);
                  } else if (v == 'delete') {
                    if (await confirm(context, 'Delete ${cat.name}?',
                        'Existing transactions will show as Uncategorized.')) {
                      store.deleteCategory(cat.id);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
