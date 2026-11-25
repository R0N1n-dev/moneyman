import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

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
        final tt = Theme.of(context).typography;
        final cs = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Settings', style: tt.x3Large.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('Appearance', style: tt.large),
            const SizedBox(height: 12),
            Tabs(
              index: store.themeMode == ThemeMode.system ? 0 : store.themeMode == ThemeMode.light ? 1 : 2,
              onChanged: (i) => store.setTheme(ThemeMode.values[i]),
              children: const [
                TabChildWidget(child: Text('System')),
                TabChildWidget(child: Text('Light')),
                TabChildWidget(child: Text('Dark')),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final a in kAccents)
                  GestureDetector(
                    onTap: () => store.setAccent(a),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(a),
                        shape: BoxShape.circle,
                      ),
                      child: store.accent == a
                          ? const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCheck,
                                color: Color(0xFFFFFFFF),
                                size: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text('General', style: tt.large),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final v = await askText(context, title: 'Currency label', initial: store.currency);
                if (v != null && v.isNotEmpty) store.setCurrency(v);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedDollar01, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Currency'),
                          Text(store.currency, style: Theme.of(context).typography.small),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Your data', style: tt.large),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => store.exportCsv(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedChartLineData01, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Export CSV'),
                          const Text('Every transaction, opens in Excel or Sheets', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => store.exportBackup(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedCloudUpload, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Back up'),
                          const Text('Save a JSON file to Drive, WhatsApp, anywhere', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final res = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                if (res.isEmpty) return;
                final path = res.first.path;
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedCloudDownload, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Restore from backup'),
                          const Text('Replaces everything in the app', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (await confirm(context, 'Delete everything?',
                    'All transactions and recurring entries will be removed. This cannot be undone.')) {
                  await store.clearAll();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedDelete01, color: cs.destructive, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delete all data'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
