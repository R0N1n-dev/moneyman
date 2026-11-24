import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import 'category_dialog.dart';

Future<void> showTxSheet(BuildContext context, {Tx? edit}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => TxSheet(edit: edit),
  );
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

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
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
    Navigator.pop(context);
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: TxType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _catId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: !isEdit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: InputDecoration(
                prefixText: '${store.currency}  ',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    avatar: Icon(c.iconData, size: 18, color: c.colorValue),
                    label: Text(c.name),
                    selected: _catId == c.id,
                    onSelected: (_) => setState(() => _catId = c.id),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  onPressed: () async {
                    final c = await showCategoryDialog(context, type: _type);
                    if (c != null) setState(() => _catId = c.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(dayLabel(_date)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Note (optional)'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final m in kMethods)
                  ChoiceChip(
                    label: Text(m),
                    selected: _method == m,
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ],
            ),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.repeat, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('One time'),
                        selected: _repeat == null,
                        onSelected: (_) => setState(() => _repeat = null),
                      ),
                      ChoiceChip(
                        label: const Text('Weekly'),
                        selected: _repeat == Repeat.weekly,
                        onSelected: (_) => setState(() => _repeat = Repeat.weekly),
                      ),
                      ChoiceChip(
                        label: const Text('Monthly'),
                        selected: _repeat == Repeat.monthly,
                        onSelected: (_) => setState(() => _repeat = Repeat.monthly),
                      ),
                    ],
                  )),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(isEdit ? 'Save changes' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
