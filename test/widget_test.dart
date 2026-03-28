// Basic smoke test for Widget Share shell.

import 'package:flutter_test/flutter_test.dart';

import 'package:widget_share/main.dart';

void main() {
  testWidgets('Home shell shows bottom navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const WidgetShareApp());

    expect(find.text('Add Widget'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });
}
