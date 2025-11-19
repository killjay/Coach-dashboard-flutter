// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coach_client_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CoachClientApp(),
      ),
    );

    // Verify that the app loads (splash screen or login screen)
    // The app will show either splash screen or login based on auth state
    await tester.pumpAndSettle();
    
    // Verify that some UI element is present (app loaded successfully)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
