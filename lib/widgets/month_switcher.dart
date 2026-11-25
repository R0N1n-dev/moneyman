import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../store.dart';
import '../utils.dart';

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Button.ghost(
            onPressed: () => store.shiftMonth(-1),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 20),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              monthLabel(store.month),
              style: Theme.of(context).typography.large.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Button.ghost(
            onPressed: store.isCurrentMonth ? null : () => store.shiftMonth(1),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20),
          ),
        ],
      ),
    );
  }
}
