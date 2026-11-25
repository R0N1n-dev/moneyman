import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets/month_switcher.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  TxType _type = TxType.expense;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).typography;
        final cur = store.currency;
        final byCat = store.byCategory(_type).entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = byCat.fold(0.0, (s, e) => s + e.value);
        final daily = store.dailyTotals(_type);
        final monthList = store.monthTxs().where((t) => t.type == _type).toList();
        final now = DateTime.now();
        final elapsed = store.isCurrentMonth ? now.day : daily.length;
        final biggest = monthList.isEmpty
            ? null
            : (monthList.toList()..sort((a, b) => b.amount.compareTo(a.amount))).first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Align(alignment: Alignment.centerLeft, child: MonthSwitcher()),
            const SizedBox(height: 8),
            Tabs(
              index: _type == TxType.expense ? 0 : 1,
              onChanged: (i) => setState(() => _type = i == 0 ? TxType.expense : TxType.income),
              children: const [
                TabChildWidget(child: Text('Expenses')),
                TabChildWidget(child: Text('Income')),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedChartAnalysis,
                        size: 64,
                        color: cs.mutedForeground,
                      ),
                      const SizedBox(height: 8),
                      Text('Nothing to chart yet', style: tt.large),
                    ],
                  ),
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 62,
                                sections: [
                                  for (final e in byCat)
                                    PieChartSectionData(
                                      value: e.value,
                                      color: store.cat(e.key).colorValue,
                                      radius: 44,
                                      title: e.value / total >= 0.08
                                          ? '${(e.value / total * 100).round()}%'
                                          : '',
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFFFFF),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_type == TxType.expense ? 'Spent' : 'Earned', style: tt.small),
                                Text(
                                  '$cur ${compact(total)}',
                                  style: tt.xLarge.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final e in byCat)
                        Builder(builder: (context) {
                          final c = store.cat(e.key);
                          final pct = e.value / total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: c.colorValue.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: HugeIcon(icon: c.iconData, size: 16, color: c.colorValue),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(c.name)),
                                          Text(
                                            money(e.value, cur),
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: pct,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      label: 'Avg per day',
                      value: '$cur ${compact(total / elapsed)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Tile(label: 'Transactions', value: '${monthList.length}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Tile(
                      label: 'Largest',
                      value: biggest == null ? '-' : '$cur ${compact(biggest.amount)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day by day', style: tt.large),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 24,
                                  getTitlesWidget: (v, meta) {
                                    final d = v.toInt();
                                    if (d != 1 && d % 5 != 0) return const SizedBox.shrink();
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text('$d', style: tt.xSmall),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < daily.length; i++)
                                BarChartGroupData(
                                  x: i + 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: daily[i],
                                      width: 5,
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _SixMonths(),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).typography;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tt.xSmall),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: tt.large.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SixMonths extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).typography;
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(store.month.year, store.month.month - i),
    ];
    final spent = [for (final m in months) store.total(TxType.expense, m)];
    final earned = [for (final m in months) store.total(TxType.income, m)];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Last 6 months', style: tt.large)),
                _Dot(color: const Color(0xFF16A34A), label: 'Income'),
                const SizedBox(width: 12),
                _Dot(color: cs.primary, label: 'Spent'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(DateFormat('MMM').format(months[v.toInt()]), style: tt.xSmall),
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < months.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: earned[i],
                            width: 10,
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          BarChartRodData(
                            toY: spent[i],
                            width: 10,
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).typography.xSmall),
      ],
    );
  }
}
