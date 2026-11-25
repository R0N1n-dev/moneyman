import 'package:shadcn_flutter/shadcn_flutter.dart';
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
}) async {
  final ctl = TextEditingController(
    text: initial == 0 ? '' : NumberFormat('0.##').format(initial),
  );
  final result = showOverlay<double>(
    context,
    DialogConfiguration(),
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        placeholder: Text(hint ?? 'Amount'),
      ),
      actions: [
        Button.ghost(
          onPressed: () => closeOverlay(ctx),
          child: const Text('Cancel'),
        ),
        Button.primary(
          onPressed: () {
            final v = double.tryParse(ctl.text.replaceAll(',', '').trim());
            closeOverlay(ctx, v ?? 0);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  return result.future;
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
}) async {
  final ctl = TextEditingController(text: initial);
  final result = showOverlay<String>(
    context,
    DialogConfiguration(),
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctl, autofocus: true),
      actions: [
        Button.ghost(
          onPressed: () => closeOverlay(ctx),
          child: const Text('Cancel'),
        ),
        Button.primary(
          onPressed: () => closeOverlay(ctx, ctl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  return result.future;
}

Future<bool> confirm(BuildContext context, String title, String message) async {
  final result = showOverlay<bool>(
    context,
    DialogConfiguration(),
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        Button.ghost(
          onPressed: () => closeOverlay(ctx, false),
          child: const Text('Cancel'),
        ),
        Button.primary(
          onPressed: () => closeOverlay(ctx, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return await result.future ?? false;
}

void toast(BuildContext context, String msg, {String? action, VoidCallback? onAction}) {
  showToast(
    context: context,
    builder: (context, overlay) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(msg)),
            if (action != null)
              Button.ghost(
                onPressed: () {
                  onAction?.call();
                  overlay.close();
                },
                child: Text(action),
              ),
          ],
        ),
      ),
    ),
  );
}
