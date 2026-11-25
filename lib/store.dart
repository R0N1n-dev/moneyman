import 'dart:convert';
import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'utils.dart';

final store = Store();

int _seq = 0;
String newId() => '${DateTime.now().microsecondsSinceEpoch}${_seq++}';

List<Category> _defaultCats() => [
      Category(id: 'food', name: 'Food', icon: 0, color: kColors[1], type: TxType.expense),
      Category(id: 'transport', name: 'Transport', icon: 1, color: kColors[6], type: TxType.expense),
      Category(id: 'airtime', name: 'Airtime & Data', icon: 2, color: kColors[8], type: TxType.expense),
      Category(id: 'rent', name: 'Rent', icon: 3, color: kColors[7], type: TxType.expense),
      Category(id: 'shopping', name: 'Shopping', icon: 4, color: kColors[10], type: TxType.expense),
      Category(id: 'bills', name: 'Bills', icon: 5, color: kColors[2], type: TxType.expense),
      Category(id: 'health', name: 'Health', icon: 6, color: kColors[0], type: TxType.expense),
      Category(id: 'fun', name: 'Entertainment', icon: 7, color: kColors[9], type: TxType.expense),
      Category(id: 'edu', name: 'Education', icon: 8, color: kColors[5], type: TxType.expense),
      Category(id: 'other', name: 'Other', icon: 9, color: kColors[11], type: TxType.expense),
      Category(id: 'salary', name: 'Salary', icon: 10, color: kColors[4], type: TxType.income),
      Category(id: 'business', name: 'Business', icon: 11, color: kColors[5], type: TxType.income),
      Category(id: 'gift', name: 'Gift', icon: 12, color: kColors[10], type: TxType.income),
      Category(id: 'otherinc', name: 'Other income', icon: 9, color: kColors[6], type: TxType.income),
    ];

class Store extends ChangeNotifier {
  List<Tx> txs = [];
  List<Category> cats = _defaultCats();
  List<Recurring> recurring = [];
  double monthlyBudget = 900000;
  String currency = 'UGX';
  ThemeMode themeMode = ThemeMode.system;
  int accent = 0xFF00897B;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  late SharedPreferences _p;

  // ---------- persistence ----------

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p.getString('data');
    if (raw != null) {
      try {
        _apply(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    applyRecurring();
  }

  void _apply(Map<String, dynamic> j) {
    final newCats = (j['cats'] as List?)
            ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList() ??
        _defaultCats();
    final newTxs =
        (j['txs'] as List?)?.map((e) => Tx.fromJson(e as Map<String, dynamic>)).toList() ?? <Tx>[];
    final newRec = (j['rec'] as List?)
            ?.map((e) => Recurring.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Recurring>[];
    cats = newCats;
    txs = newTxs;
    recurring = newRec;
    monthlyBudget = (j['budget'] as num?)?.toDouble() ?? monthlyBudget;
    currency = (j['currency'] as String?) ?? currency;
    themeMode = ThemeMode.values[((j['theme'] as num?)?.toInt() ?? 0).clamp(0, 2).toInt()];
    accent = (j['accent'] as num?)?.toInt() ?? accent;
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'budget': monthlyBudget,
        'currency': currency,
        'theme': themeMode.index,
        'accent': accent,
        'cats': cats.map((c) => c.toJson()).toList(),
        'txs': txs.map((t) => t.toJson()).toList(),
        'rec': recurring.map((r) => r.toJson()).toList(),
      };

  void _commit() {
    _p.setString('data', jsonEncode(toJson()));
    notifyListeners();
  }

  // ---------- queries ----------

  Category cat(String id) => cats.firstWhere(
        (c) => c.id == id,
        orElse: () => Category(
          id: '?',
          name: 'Uncategorized',
          icon: 9,
          color: 0xFF9E9E9E,
          type: TxType.expense,
        ),
      );

  List<Tx> monthTxs([DateTime? m]) {
    final mm = m ?? month;
    return txs.where((t) => t.date.year == mm.year && t.date.month == mm.month).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double total(TxType type, [DateTime? m]) =>
      monthTxs(m).where((t) => t.type == type).fold(0.0, (s, t) => s + t.amount);

  Map<String, double> byCategory(TxType type, [DateTime? m]) {
    final out = <String, double>{};
    for (final t in monthTxs(m)) {
      if (t.type == type) out[t.categoryId] = (out[t.categoryId] ?? 0) + t.amount;
    }
    return out;
  }

  List<double> dailyTotals(TxType type, [DateTime? m]) {
    final mm = m ?? month;
    final days = DateTime(mm.year, mm.month + 1, 0).day;
    final out = List<double>.filled(days, 0);
    for (final t in monthTxs(mm)) {
      if (t.type == type) out[t.date.day - 1] += t.amount;
    }
    return out;
  }

  // ---------- actions ----------

  void shiftMonth(int delta) {
    final next = DateTime(month.year, month.month + delta);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    month = next;
    notifyListeners();
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  void saveTx(Tx t) {
    final i = txs.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      txs[i] = t;
    } else {
      txs.add(t);
    }
    _commit();
  }

  void deleteTx(String id) {
    txs.removeWhere((t) => t.id == id);
    _commit();
  }

  void addRecurring(Recurring r) {
    recurring.add(r);
    _commit();
  }

  void deleteRecurring(String id) {
    recurring.removeWhere((r) => r.id == id);
    _commit();
  }

  void applyRecurring() {
    final today = dayOnly(DateTime.now());
    var changed = false;
    for (final r in recurring) {
      var guard = 0;
      while (!dayOnly(r.next).isAfter(today) && guard++ < 400) {
        txs.add(Tx(
          id: newId(),
          type: r.type,
          amount: r.amount,
          categoryId: r.categoryId,
          note: r.note,
          date: r.next,
          method: r.method,
        ));
        r.next = r.advance(r.next);
        changed = true;
      }
    }
    if (changed) _commit();
  }

  void saveCategory(Category c) {
    final i = cats.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      cats[i] = c;
    } else {
      cats.add(c);
    }
    _commit();
  }

  void deleteCategory(String id) {
    cats.removeWhere((c) => c.id == id);
    _commit();
  }

  void setBudget(double v) {
    monthlyBudget = v;
    _commit();
  }

  void setCurrency(String v) {
    currency = v.isEmpty ? currency : v;
    _commit();
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    _commit();
  }

  void setAccent(int c) {
    accent = c;
    _commit();
  }

  Future<void> clearAll() async {
    txs = [];
    recurring = [];
    cats = _defaultCats();
    _commit();
  }

  // ---------- export / backup ----------

  Future<void> exportCsv() async {
    final sb = StringBuffer('Date,Type,Category,Amount,Method,Note\n');
    final sorted = [...txs]..sort((a, b) => a.date.compareTo(b.date));
    final f = DateFormat('yyyy-MM-dd');
    for (final t in sorted) {
      sb.writeln([
        f.format(t.date),
        t.type.name,
        cat(t.categoryId).name,
        t.amount,
        t.method,
        t.note,
      ].map(_csv).join(','));
    }
    await _share('expenses.csv', sb.toString());
  }

  Future<void> exportBackup() => _share('expense-tracker-backup.json', jsonEncode(toJson()));

  bool restore(String raw) {
    try {
      _apply(jsonDecode(raw) as Map<String, dynamic>);
      _commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _csv(Object v) {
    final s = '$v';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  Future<void> _share(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}
