// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eye_focus/main.dart';
import 'package:eye_focus/services/router.dart' show routerProvider;

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    final fakeRouter = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(fakeRouter)],
        child: const EyeFocusApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
