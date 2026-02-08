// Basic smoke test for SICOPA app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sicopa/main.dart';

void main() {
  testWidgets('SICOPA app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(SicopaApp());

    // Verify that the app title is displayed
    expect(find.text('SICOPA'), findsOneWidget);
  });
}
