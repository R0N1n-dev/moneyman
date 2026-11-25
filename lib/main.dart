import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shadcn_flutter_material/shadcn_flutter_material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'screens/home.dart';
import 'screens/plan.dart';
import 'screens/settings.dart';
import 'screens/stats.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets/tx_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialShadcnApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        themeMode: store.themeMode,
        theme: buildTheme(store.accent, Brightness.light),
        darkTheme: buildTheme(store.accent, Brightness.dark),
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.applyRecurring();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      footers: [
        if (_index == 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Button.primary(
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 20),
                  SizedBox(width: 8),
                  Text('Add'),
                ],
              ),
              onPressed: () => showTxSheet(context),
            ),
          ),
        NavigationBar(
          selectedKey: ValueKey(_index),
          onSelected: (key) => setState(() => _index = key as int),
          children: const [
            NavigationItem(
              key: ValueKey(0),
              label: Text('Home'),
              child: HugeIcon(icon: HugeIcons.strokeRoundedHome01, size: 24),
            ),
            NavigationItem(
              key: ValueKey(1),
              label: Text('Stats'),
              child: HugeIcon(icon: HugeIcons.strokeRoundedChart01, size: 24),
            ),
            NavigationItem(
              key: ValueKey(2),
              label: Text('Plan'),
              child: HugeIcon(icon: HugeIcons.strokeRoundedWallet01, size: 24),
            ),
            NavigationItem(
              key: ValueKey(3),
              label: Text('Settings'),
              child: HugeIcon(icon: HugeIcons.strokeRoundedSettings01, size: 24),
            ),
          ],
        ),
      ],
      child: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const [HomePage(), StatsPage(), PlanPage(), SettingsPage()],
        ),
      ),
    );
  }
}
