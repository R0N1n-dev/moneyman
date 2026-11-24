import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets/month_switcher.dart';
import '../widgets/tx_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TxType? _filter;
  bool _searching = false;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = _query.text.trim().toLowerCase();
        var list = store.monthTxs();
        if (_filter != null) list = list.where((t) => t.type == _filter).toList();
        if (q.isNotEmpty) {
          list = list
              .where((t) =>
                  t.note.toLowerCase().contains(q) ||
                  store.cat(t.categoryId).name.toLowerCase().contains(q) ||
                  t.amount.toString().contains(q))
              .toList();
        }

        final groups = <DateTime, List<Tx>>{};
        for (final t in list) {
          groups.putIfAbsent(dayOnly(t.date), () => []).add(t);
        }
        final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: _searching
                  ? TextField(
                      controller: _query,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search notes, categories, amounts',
                        prefixIcon: Icon(Icons.search),
                      ),
                    )
                  : const MonthSwitcher(),
              actions: [
                IconButton(
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    if (!_searching) _query.clear();
                  }),
                ),
              ],
            ),
            SliverToBoxAdapter(child: _Summary()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    ChoiceChip(
                      label: const Text('Expenses'),
                      selected: _filter == TxType.expense,
                      onSelected: (_) => setState(() => _filter = TxType.expense),
                    ),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: _filter == TxType.income,
                      onSelected: (_) => setState(() => _filter = TxType.income),
                    ),
                  ],
                ),
              ),
            ),
            if (days.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          q.isNotEmpty ? 'Nothing matches your search' : 'No transactions this month',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (q.isEmpty) ...[
                          const SizedBox(height: 4),
                          const Text('Tap Add to record your first one.'),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList.separated(
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _DayGroup(
                    key: ValueKey('${days[i].millisecondsSinceEpoch}-$_filter-${_searching && q.isNotEmpty}'),
                    day: days[i],
                    items: groups[days[i]]!,
                    initiallyExpanded: i == 0,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final income = store.total(TxType.income);
    final spent = store.total(TxType.expense);
    final balance = income - spent;
    final budget = store.monthlyBudget;
    final ratio = budget > 0 ? spent / budget : 0.0;
    final now = DateTime.now();
    final daysInMonth = DateTime(store.month.year, store.month.month + 1, 0).day;
    final daysLeft = store.isCurrentMonth ? daysInMonth - now.day + 1 : 0;
    final remaining = budget - spent;

    final barColor = ratio >= 1
        ? cs.error
        : ratio >= 0.8
            ? Colors.orange
            : cs.primary;

    String hint;
    if (budget <= 0) {
      hint = 'Set a monthly budget in Plan';
    } else if (remaining < 0) {
      hint = 'Over budget by ${money(-remaining, store.currency)}';
    } else if (daysLeft > 0) {
      hint = '${money(remaining / daysLeft, store.currency)} per day for $daysLeft more days';
    } else {
      hint = '${money(remaining, store.currency)} left';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance', style: tt.labelLarge?.copyWith(color: cs.onPrimaryContainer)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                money(balance, store.currency),
                style: tt.headlineLarge?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.arrow_downward,
                    label: 'Income',
                    value: money(income, store.currency),
                    color: cs.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    icon: Icons.arrow_upward,
                    label: 'Spent',
                    value: money(spent, store.currency),
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            if (budget > 0) ...[
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
                color: barColor,
                backgroundColor: cs.onPrimaryContainer.withValues(alpha: 0.15),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              budget > 0
                  ? '${(ratio * 100).round()}% of ${money(budget, store.currency)} used. $hint'
                  : hint,
              style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.labelSmall?.copyWith(color: color)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: tt.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayGroup extends StatelessWidget {
  final DateTime day;
  final List<Tx> items;
  final bool initiallyExpanded;
  const _DayGroup({super.key, required this.day, required this.items, required this.initiallyExpanded});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spent = items.where((t) => t.type == TxType.expense).fold(0.0, (s, t) => s + t.amount);
    final earned = items.where((t) => t.type == TxType.income).fold(0.0, (s, t) => s + t.amount);
    final net = earned - spent;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(dayLabel(day), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(
              '${net >= 0 ? '+' : '-'}${money(net.abs(), store.currency)}',
              style: TextStyle(
                fontSize: 14,
                color: net >= 0 ? Colors.green.shade600 : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Text('${items.length} ${items.length == 1 ? 'item' : 'items'}'),
        children: [for (final t in items) _TxTile(tx: t)],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Tx tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = store.cat(tx.categoryId);
    final isIncome = tx.type == TxType.income;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: cs.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      onDismissed: (_) {
        store.deleteTx(tx.id);
        toast(context, 'Deleted', action: 'Undo', onAction: () => store.saveTx(tx));
      },
      child: ListTile(
        onTap: () => showTxSheet(context, edit: tx),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: c.colorValue.withValues(alpha: 0.18),
          child: Icon(c.iconData, color: c.colorValue, size: 22),
        ),
        title: Text(
          tx.note.isEmpty ? c.name : tx.note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${c.name} \u00b7 ${tx.method}'),
        trailing: Text(
          '${isIncome ? '+' : '-'}${money(tx.amount, store.currency)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isIncome ? Colors.green.shade600 : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
