import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

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
                  t.amount.toString().contains(q) ||
                  t.method.toLowerCase().contains(q))
              .toList();
        }

        final groups = <DateTime, List<Tx>>{};
        for (final t in list) {
          groups.putIfAbsent(dayOnly(t.date), () => []).add(t);
        }
        final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: const MonthSwitcher()),
                    if (_searching)
                      Expanded(
                        child: TextField(
                          controller: _query,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          placeholder: const Text('Search...'),
                        ),
                      )
                    else
                      const Spacer(),
                    Button.ghost(
                      onPressed: () => setState(() {
                        _searching = !_searching;
                        if (!_searching) _query.clear();
                      }),
                      child: HugeIcon(
                        icon: _searching
                            ? HugeIcons.strokeRoundedCancel01
                            : HugeIcons.strokeRoundedSearch01,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _Summary()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      onPressed: () => setState(() => _filter = null),
                      style: _filter == null ? ButtonStyle.primary() : ButtonStyle.outline(),
                      child: const Text('All'),
                    ),
                    Chip(
                      onPressed: () => setState(() => _filter = TxType.expense),
                      style: _filter == TxType.expense ? ButtonStyle.primary() : ButtonStyle.outline(),
                      child: const Text('Expenses'),
                    ),
                    Chip(
                      onPressed: () => setState(() => _filter = TxType.income),
                      style: _filter == TxType.income ? ButtonStyle.primary() : ButtonStyle.outline(),
                      child: const Text('Income'),
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
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedReceipt,
                          size: 64,
                          color: Theme.of(context).colorScheme.mutedForeground,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q.isNotEmpty ? 'Nothing matches your search' : 'No transactions this month',
                          style: Theme.of(context).typography.large,
                        ),
                        if (q.isEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap Add to record your first one.',
                            style: Theme.of(context).typography.small,
                          ),
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
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
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
    final income = store.total(TxType.income);
    final spent = store.total(TxType.expense);
    final balance = income - spent;
    final budget = store.monthlyBudget;
    final ratio = budget > 0 ? spent / budget : 0.0;
    final now = DateTime.now();
    final daysInMonth = DateTime(store.month.year, store.month.month + 1, 0).day;
    final daysLeft = store.isCurrentMonth ? daysInMonth - now.day + 1 : 0;
    final remaining = budget - spent;

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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance', style: Theme.of(context).typography.base),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  money(balance, store.currency),
                  style: Theme.of(context).typography.x3Large.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      label: 'Income',
                      value: money(income, store.currency),
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      icon: HugeIcons.strokeRoundedArrowUp01,
                      label: 'Spent',
                      value: money(spent, store.currency),
                    ),
                  ),
                ],
              ),
              if (budget > 0) ...[
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0).toDouble(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                budget > 0
                    ? '${(ratio * 100).round()}% of ${money(budget, store.currency)} used. $hint'
                    : hint,
                style: Theme.of(context).typography.small,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.muted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: HugeIcon(icon: icon, size: 16, color: cs.mutedForeground),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).typography.xSmall),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).typography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
    final spent = items.where((t) => t.type == TxType.expense).fold(0.0, (s, t) => s + t.amount);
    final earned = items.where((t) => t.type == TxType.income).fold(0.0, (s, t) => s + t.amount);
    final net = earned - spent;

    return Card(
      child: Collapsible(
        isExpanded: initiallyExpanded,
        children: [
          CollapsibleTrigger(
            child: Row(
              children: [
                Expanded(
                  child: Text(dayLabel(day), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(
                  '${net >= 0 ? '+' : '-'}${money(net.abs(), store.currency)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: net >= 0 ? const Color(0xFF16A34A) : Theme.of(context).colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          CollapsibleContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('${items.length} ${items.length == 1 ? 'item' : 'items'}', style: Theme.of(context).typography.small),
                ),
                for (final t in items) _TxTile(tx: t),
              ],
            ),
          ),
        ],
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

    return GestureDetector(
      onTap: () => showTxSheet(context, edit: tx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.colorValue.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: HugeIcon(icon: c.iconData, color: c.colorValue, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note.isEmpty ? c.name : tx.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).typography.base,
                  ),
                  Text('${c.name} · ${tx.method}', style: Theme.of(context).typography.small),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${money(tx.amount, store.currency)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isIncome ? const Color(0xFF16A34A) : cs.foreground,
              ),
            ),
            const SizedBox(width: 8),
            Button.ghost(
              onPressed: () {
                store.deleteTx(tx.id);
                toast(context, 'Deleted', action: 'Undo', onAction: () => store.saveTx(tx));
              },
              child: HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 18, color: cs.destructive),
            ),
          ],
        ),
      ),
    );
  }
}
