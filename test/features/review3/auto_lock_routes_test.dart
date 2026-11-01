import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/help_now/help_now_screen.dart';
import 'package:cwc_health_app/features/how_to/how_to_screen.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/onboarding/disclaimer_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/health_seed.dart';
import '../../support/stub_nearby.dart';

/// Auto-lock closes only My Health screens. A person on a long crisis call
/// must come back to Help Now, not to the home tabs.
void main() {
  Future<void> pumpApp(WidgetTester tester, HealthController health) async {
    SharedPreferences.setMockInitialValues({disclaimerAckPref: true});
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CwcApp(
        healthController: health,
        disclaimerAcknowledged: true,
        nearbyRepository: StubNearbyRepository(result: stubNearbyResult()),
        linkLauncher: (_) async => true,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> awayFor(WidgetTester tester, Duration away) async {
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump(away);
    for (final state in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  Future<HealthController> lockedLater() async {
    final health = await seededController();
    await health.setPin('1234');
    return health;
  }

  testWidgets('Help Now opened from a My Health form stays open; the form '
      'under it closes', (tester) async {
    final health = await lockedLater();
    await pumpApp(tester, health);
    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Add').first);
    await tester.pumpAndSettle();
    expect(find.text('Add appointment'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Help Now').last);
    await tester.pumpAndSettle();
    expect(find.byType(HelpNowScreen), findsWidgets);

    // A 32 second call to 988.
    await awayFor(tester, const Duration(seconds: 32));

    expect(health.isUnlocked, isFalse);
    expect(find.text('Call 988'), findsWidgets, reason: 'Help Now is open');
    expect(find.text('Add appointment', skipOffstage: false), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('My Health is locked'), findsOneWidget);
  });

  testWidgets('a screen that is not My Health stays open', (tester) async {
    final health = await lockedLater();
    await pumpApp(tester, health);
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How to Use This App'));
    await tester.pumpAndSettle();
    expect(find.byType(HowToScreen), findsOneWidget);

    await awayFor(tester, const Duration(seconds: 32));

    expect(health.isUnlocked, isFalse);
    expect(find.byType(HowToScreen), findsOneWidget);
  });

  testWidgets('a dialog opened from a My Health form closes with it', (
    tester,
  ) async {
    final health = await lockedLater();
    await pumpApp(tester, health);
    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    final med = find.text('Test Medicine');
    await tester.tap(med);
    await tester.pumpAndSettle();
    final delete = find.widgetWithText(OutlinedButton, 'Delete');
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Delete medication?'), findsOneWidget);

    await awayFor(tester, const Duration(seconds: 32));

    expect(find.text('Delete medication?'), findsNothing);
    expect(find.text('Edit medication', skipOffstage: false), findsNothing);
    expect(find.text('My Health is locked'), findsOneWidget);
    expect(health.medications, hasLength(1), reason: 'nothing was deleted');
  });
}
