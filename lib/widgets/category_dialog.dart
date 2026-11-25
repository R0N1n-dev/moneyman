import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../models.dart';
import '../store.dart';

/// Create or edit a category. Returns the saved category, or null if cancelled.
Future<Category?> showCategoryDialog(
  BuildContext context, {
  required TxType type,
  Category? edit,
}) async {
  final nameCtl = TextEditingController(text: edit?.name ?? '');
  var icon = edit?.icon ?? 9;
  var color = edit?.color ?? kColors[7];

  final result = showOverlay<Category>(
    context,
    DialogConfiguration(),
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
                placeholder: const Text('Name'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < kIcons.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => icon = i),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: icon == i
                              ? Color(color)
                              : Theme.of(ctx).colorScheme.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: kIcons[i],
                            size: 20,
                            color: icon == i ? const Color(0xFFFFFFFF) : Theme.of(ctx).colorScheme.mutedForeground,
                          ),
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
                    GestureDetector(
                      onTap: () => setState(() => color = c),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                        ),
                        child: color == c
                            ? const Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedCheck,
                                  color: Color(0xFFFFFFFF),
                                  size: 16,
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Button.ghost(
            onPressed: () => closeOverlay(ctx),
            child: const Text('Cancel'),
          ),
          Button.primary(
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
              closeOverlay(ctx, c);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  return result.future;
}
