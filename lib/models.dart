import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' show Color;

enum TxType { expense, income }

enum Repeat { weekly, monthly }

const List<List<List<dynamic>>> kIcons = [
  HugeIcons.strokeRoundedRestaurant01,
  HugeIcons.strokeRoundedBus01,
  HugeIcons.strokeRoundedSmartPhone01,
  HugeIcons.strokeRoundedHome01,
  HugeIcons.strokeRoundedShoppingBag01,
  HugeIcons.strokeRoundedReceipt,
  HugeIcons.strokeRoundedHeartPulse,
  HugeIcons.strokeRoundedFilm01,
  HugeIcons.strokeRoundedGraduationScroll,
  HugeIcons.strokeRoundedTag01,
  HugeIcons.strokeRoundedBriefcase01,
  HugeIcons.strokeRoundedStore01,
  HugeIcons.strokeRoundedGift,
  HugeIcons.strokeRoundedWallet01,
  HugeIcons.strokeRoundedAirplane01,
  HugeIcons.strokeRoundedCat,
  HugeIcons.strokeRoundedDumbbell01,
  HugeIcons.strokeRoundedGasPipe,
  HugeIcons.strokeRoundedCoffee01,
  HugeIcons.strokeRoundedBaby01,
  HugeIcons.strokeRoundedSettings01,
  HugeIcons.strokeRoundedWifi01,
  HugeIcons.strokeRoundedHeart,
];

const List<int> kColors = [
  0xFFEF5350,
  0xFFFF7043,
  0xFFFFA726,
  0xFFFFCA28,
  0xFF9CCC65,
  0xFF26A69A,
  0xFF29B6F6,
  0xFF5C6BC0,
  0xFF7E57C2,
  0xFFAB47BC,
  0xFFEC407A,
  0xFF8D6E63,
];

const List<String> kMethods = ['Cash', 'Mobile Money', 'Card', 'Bank'];

class Category {
  String id;
  String name;
  int icon;
  int color;
  TxType type;
  double budget; // monthly limit, 0 = no limit

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.budget = 0,
  });

  List<List<dynamic>> get iconData => kIcons[icon % kIcons.length];
  Color get colorValue => Color(color);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'type': type.index,
        'budget': budget,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: (j['icon'] as num).toInt(),
        color: (j['color'] as num).toInt(),
        type: TxType.values[(j['type'] as num).toInt()],
        budget: (j['budget'] as num?)?.toDouble() ?? 0,
      );
}

class Tx {
  final String id;
  final TxType type;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final String method;

  Tx({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'amount': amount,
        'cat': categoryId,
        'note': note,
        'date': date.millisecondsSinceEpoch,
        'method': method,
      };

  factory Tx.fromJson(Map<String, dynamic> j) => Tx(
        id: j['id'] as String,
        type: TxType.values[(j['type'] as num).toInt()],
        amount: (j['amount'] as num).toDouble(),
        categoryId: j['cat'] as String,
        note: (j['note'] as String?) ?? '',
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
        method: (j['method'] as String?) ?? 'Cash',
      );
}

class Recurring {
  final String id;
  final TxType type;
  final double amount;
  final String categoryId;
  final String note;
  final String method;
  final Repeat repeat;
  final int day; // original day of month, used for monthly repeats
  DateTime next;

  Recurring({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.method,
    required this.repeat,
    required this.day,
    required this.next,
  });

  DateTime advance(DateTime d) {
    if (repeat == Repeat.weekly) return DateTime(d.year, d.month, d.day + 7);
    final y = d.year;
    final m = d.month + 1;
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, day < last ? day : last);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'amount': amount,
        'cat': categoryId,
        'note': note,
        'method': method,
        'repeat': repeat.index,
        'day': day,
        'next': next.millisecondsSinceEpoch,
      };

  factory Recurring.fromJson(Map<String, dynamic> j) => Recurring(
        id: j['id'] as String,
        type: TxType.values[(j['type'] as num).toInt()],
        amount: (j['amount'] as num).toDouble(),
        categoryId: j['cat'] as String,
        note: (j['note'] as String?) ?? '',
        method: (j['method'] as String?) ?? 'Cash',
        repeat: Repeat.values[(j['repeat'] as num).toInt()],
        day: (j['day'] as num).toInt(),
        next: DateTime.fromMillisecondsSinceEpoch((j['next'] as num).toInt()),
      );
}
