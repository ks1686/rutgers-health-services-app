import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/data/content_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/stub_nearby.dart';

/// H1: a storage failure at startup must never hide crisis help.
void main() {
  setUpAll(() async {
    await loadLearnTopics();
  });

  testWidgets('prefs and secure storage both failing still opens the app', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CwcApp(
        openSharedPreferences: () async => throw StateError('prefs broken'),
        openHealthStore: (_) async => throw StateError('keystore broken'),
        nearbyRepository: StubNearbyRepository(result: stubNearbyResult()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Before you continue'), findsOneWidget);
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('My Health cannot open'), findsOneWidget);

    await tester.tap(find.text('Help Now'));
    await tester.pumpAndSettle();
    expect(find.textContaining('911'), findsWidgets);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
