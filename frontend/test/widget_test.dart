// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kahoot_app/main.dart';

void main() {
  testWidgets('App shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KahootApp());
    await tester.pumpAndSettle();

    // Verify that the login screen elements are present.
    expect(find.text('Present Perfect\nQuiz!'), findsOneWidget);
    expect(find.text('Join Game'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
