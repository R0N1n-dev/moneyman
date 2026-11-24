import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../store.dart';

/// Create or edit a category. Returns the saved category, or null if cancelled.
Future<Category?> showCategoryDialog(
  BuildContext context, {
  required TxType type,
  Category? edit,
}) {
  final nameCtl = TextEditingController(text: edit?.name ?? '');
  var icon = edit?.icon ?? 9;
  var color = edit?.color ?? kColors[7];

  return showDialog<Category>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(edit == null ? 'New category' : 'Edit category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtl,
                autofocus: edit == null,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < kIcons.length; i++)
                    InkResponse(
                      onTap: () => setState(() => icon = i),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: icon == i
                            ? Color(color)
                            : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          kIcons[i],
                          size: 20,
                          color: icon == i ? Colors.white : Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in kColors)
                    InkResponse(
                      onTap: () => setState(() => color = c),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(c),
                        child: color == c
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtl.text.trim();
              if (name.isEmpty) return;
              final c = Category(
                id: edit?.id ?? newId(),
                name: name,
                icon: icon,
                color: color,
                type: type,
                budget: edit?.budget ?? 0,
              );
              store.saveCategory(c);
              Navigator.pop(ctx, c);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
