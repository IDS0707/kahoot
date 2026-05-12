import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kahoot_app/app.dart';

void main() {
  testWidgets('App boots without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KahootApp()));
    // Don't pumpAndSettle — particle/orb animations loop forever.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(KahootApp), findsOneWidget);
  });
}
