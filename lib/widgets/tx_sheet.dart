import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../models.dart';
import '../store.dart';
import 'category_dialog.dart';

Future<void> showTxSheet(BuildContext context, {Tx? edit}) async {
  final result = showOverlay<void>(
    context,
    SheetConfiguration(
      position: OverlayPosition.bottom,
      draggable: true,
      useSafeArea: true,
    ),
    builder: (_) => TxSheet(edit: edit),
  );
  await result.future;
}

class TxSheet extends StatefulWidget {
  final Tx? edit;
  const TxSheet({super.key, this.edit});

  @override
  State<TxSheet> createState() => _TxSheetState();
}

class _TxSheetState extends State<TxSheet> {
  late TxType _type;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String? _catId;
  late DateTime _date;
  late String _method;
  Repeat? _repeat;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _type = e?.type ?? TxType.expense;
    _amount = TextEditingController(
      text: e == null ? '' : e.amount.toString().replaceFirst(RegExp(r'\.0$'), ''),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _catId = e?.categoryId;
    _date = e?.date ?? DateTime.now();
    _method = e?.method ?? kMethods.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _pickDate(DateTime? d) {
    if (d == null) return;
    final now = DateTime.now();
    setState(() => _date = DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second));
  }

  void _save() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    if (_catId == null) {
      setState(() => _error = 'Pick a category');
      return;
    }
    final tx = Tx(
      id: widget.edit?.id ?? newId(),
      type: _type,
      amount: amount,
      categoryId: _catId!,
      note: _note.text.trim(),
      date: _date,
      method: _method,
    );
    store.saveTx(tx);
    if (_repeat != null && widget.edit == null) {
      final r = Recurring(
        id: newId(),
        type: _type,
        amount: amount,
        categoryId: _catId!,
        note: tx.note,
        method: _method,
        repeat: _repeat!,
        day: _date.day,
        next: DateTime(_date.year, _date.month, _date.day),
      );
      r.next = r.advance(r.next);
      store.addRecurring(r);
    }
    closeOverlay(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cats = store.cats.where((c) => c.type == _type).toList();
    final isEdit = widget.edit != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit transaction' : 'New transaction',
              style: Theme.of(context).typography.xLarge,
            ),
            const SizedBox(height: 16),
            Tabs(
              index: _type == TxType.expense ? 0 : 1,
              onChanged: (i) => setState(() {
                _type = i == 0 ? TxType.expense : TxType.income;
                _catId = null;
              }),
              children: const [
                TabChildWidget(child: Text('Expense')),
                TabChildWidget(child: Text('Income')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: !isEdit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              placeholder: Text('${store.currency} 0'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in cats)
                  Chip(
                    leading: HugeIcon(icon: c.iconData, size: 18, color: c.colorValue),
                    onPressed: () => setState(() => _catId = c.id),
                    style: _catId == c.id ? ButtonStyle.primary() : ButtonStyle.outline(),
                    child: Text(c.name),
                  ),
                Chip(
                  leading: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18),
                  onPressed: () async {
                    final c = await showCategoryDialog(context, type: _type);
                    if (c != null) setState(() => _catId = c.id);
                  },
                  style: ButtonStyle.outline(),
                  child: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DatePicker(
              value: _date,
              onChanged: _pickDate,
              placeholder: const Text('Select date'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              placeholder: const Text('Note (optional)'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final m in kMethods)
                  Chip(
                    onPressed: () => setState(() => _method = m),
                    style: _method == m ? ButtonStyle.primary() : ButtonStyle.outline(),
                    child: Text(m),
                  ),
              ],
            ),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedRepeat, size: 18, color: cs.mutedForeground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        onPressed: () => setState(() => _repeat = null),
                        style: _repeat == null ? ButtonStyle.primary() : ButtonStyle.outline(),
                        child: const Text('One time'),
                      ),
                      Chip(
                        onPressed: () => setState(() => _repeat = Repeat.weekly),
                        style: _repeat == Repeat.weekly ? ButtonStyle.primary() : ButtonStyle.outline(),
                        child: const Text('Weekly'),
                      ),
                      Chip(
                        onPressed: () => setState(() => _repeat = Repeat.monthly),
                        style: _repeat == Repeat.monthly ? ButtonStyle.primary() : ButtonStyle.outline(),
                        child: const Text('Monthly'),
                      ),
                    ],
                  )),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.destructive)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Button.primary(
                onPressed: _save,
                child: Text(isEdit ? 'Save changes' : 'Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
