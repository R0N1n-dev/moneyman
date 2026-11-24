import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String money(double v, String cur) => '$cur ${NumberFormat('#,##0.##').format(v)}';

String compact(double v) => NumberFormat.compact().format(v);

String monthLabel(DateTime d) => DateFormat('MMMM yyyy').format(d);

String dayLabel(DateTime d) {
  final today = dayOnly(DateTime.now());
  final diff = today.difference(dayOnly(d)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE, d MMM').format(d);
}

Future<double?> askNumber(
  BuildContext context, {
  required String title,
  double initial = 0,
  String? hint,
}) {
  final ctl = TextEditingController(
    text: initial == 0 ? '' : NumberFormat('0.##').format(initial),
  );
  return showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(hintText: hint ?? 'Amount'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(ctl.text.replaceAll(',', '').trim());
            Navigator.pop(ctx, v ?? 0);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  final ctl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctl, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String message) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String msg, {String? action, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {}),
    ),
  );
}
