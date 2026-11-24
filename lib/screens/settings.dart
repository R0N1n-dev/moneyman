import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../store.dart';
import '../theme.dart';
import '../utils.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tt = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Settings', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('Appearance', style: tt.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {store.themeMode},
              onSelectionChanged: (s) => store.setTheme(s.first),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final a in kAccents)
                  InkResponse(
                    onTap: () => store.setAccent(a),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(a),
                      child: store.accent == a
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text('General', style: tt.titleMedium),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Currency'),
              subtitle: Text(store.currency),
              onTap: () async {
                final v = await askText(context, title: 'Currency label', initial: store.currency);
                if (v != null && v.isNotEmpty) store.setCurrency(v);
              },
            ),
            const SizedBox(height: 16),
            Text('Your data', style: tt.titleMedium),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.table_view_outlined),
              title: const Text('Export CSV'),
              subtitle: const Text('Every transaction, opens in Excel or Sheets'),
              onTap: () => store.exportCsv(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Back up'),
              subtitle: const Text('Save a JSON file to Drive, WhatsApp, anywhere'),
              onTap: () => store.exportBackup(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore),
              title: const Text('Restore from backup'),
              subtitle: const Text('Replaces everything in the app'),
              onTap: () async {
                final res = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                final path = res?.single.path;
                if (path == null || !context.mounted) return;
                final ok = await confirm(
                  context,
                  'Restore backup?',
                  'This replaces all current data with the backup file.',
                );
                if (!ok) return;
                final raw = await File(path).readAsString();
                if (!context.mounted) return;
                toast(context, store.restore(raw) ? 'Backup restored' : 'That file is not a valid backup');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
              title: const Text('Delete all data'),
              onTap: () async {
                if (await confirm(context, 'Delete everything?',
                    'All transactions and recurring entries will be removed. This cannot be undone.')) {
                  await store.clearAll();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
