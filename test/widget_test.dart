import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter_material/shadcn_flutter_material.dart';

import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('ExpenseTracker smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseApp());
    await tester.pumpAndSettle();

    // Verify that our app builds without errors
    expect(find.byType(MaterialShadcnApp), findsOneWidget);
  });
}
