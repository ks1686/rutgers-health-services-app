import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/help_now/help_now_config.dart';
import 'package:cwc_health_app/features/help_now/help_now_screen.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/my_health/data/pin_hasher.dart';
import 'package:cwc_health_app/features/my_health/health_scope.dart';
import 'package:cwc_health_app/features/my_health/wallet_card_screen.dart';
import 'package:cwc_health_app/features/onboarding/disclaimer_prefs.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/failing_stores.dart';
import '../../support/health_seed.dart';
import '../../support/stub_nearby.dart';

class _SlowHasher extends PinHasher {
  _SlowHasher() : super(iterations: 1000, runInBackground: false);

  @override
  Future<bool> verify(String pin, String stored) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return super.verify(pin, stored);
  }
}

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
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
  }

  void goAway(WidgetTester tester) {
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  void comeBack(WidgetTester tester) {
    for (final state in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  group('N1 auto-lock closes what is open over My Health', () {
    testWidgets('an open form is closed and the PIN wall shows', (
      tester,
    ) async {
      final health = await seededController();
      await health.setPin('1234');
      await pumpApp(tester, health);
      await tester.tap(find.widgetWithText(TextButton, 'Add').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Dr. Typed');
      expect(find.text('Add appointment'), findsOneWidget);

      goAway(tester);
      await tester.pump(const Duration(seconds: 32));
      comeBack(tester);
      await tester.pumpAndSettle();

      expect(health.isUnlocked, isFalse);
      expect(find.text('Add appointment'), findsNothing);
      expect(find.text('Dr. Typed'), findsNothing);
      expect(find.text('My Health is locked'), findsOneWidget);
    });

    testWidgets('the Wallet Card and its edit dialog are closed', (
      tester,
    ) async {
      final health = await seededController();
      await health.setPin('1234');
      await pumpApp(tester, health);
      final wallet = find.text('Show My Wallet Card');
      await tester.scrollUntilVisible(wallet, 300);
      await tester.pumpAndSettle();
      await tester.tap(wallet);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit wallet details'));
      await tester.pumpAndSettle();
      expect(find.text('Wallet details'), findsOneWidget);

      goAway(tester);
      await tester.pump(const Duration(seconds: 32));
      comeBack(tester);
      await tester.pumpAndSettle();

      expect(find.text('Wallet details'), findsNothing);
      expect(find.text('My Health Snapshot'), findsNothing);
      expect(find.textContaining('Test Medicine'), findsNothing);
      expect(find.text('My Health is locked'), findsOneWidget);
    });

    testWidgets('without a PIN nothing is closed', (tester) async {
      final health = await seededController();
      await pumpApp(tester, health);
      await tester.tap(find.widgetWithText(TextButton, 'Add').first);
      await tester.pumpAndSettle();
      goAway(tester);
      await tester.pump(const Duration(seconds: 32));
      comeBack(tester);
      await tester.pumpAndSettle();
      expect(find.text('Add appointment'), findsOneWidget);
    });
  });

  testWidgets('N3 Enter PIN waits while a PIN is being checked', (
    tester,
  ) async {
    final health = HealthController(
      InMemoryHealthStore(),
      pinHasher: _SlowHasher(),
    );
    await health.load();
    await health.setPin('1234');
    health.lock();
    await pumpApp(tester, health);

    await tester.tap(find.byKey(const ValueKey('enter-pin')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('enter-pin')),
    );
    expect(button.onPressed, isNull, reason: 'a check is still running');

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('enter-pin')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a failed wallet save keeps the dialog and the typed text', (
    tester,
  ) async {
    final store = FlakyHealthStore();
    final health = HealthController(store);
    await health.load();
    store.failWrites = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: HealthScope(controller: health, child: const WalletCardScreen()),
      ),
    );
    await tester.tap(find.byTooltip('Edit wallet details'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Sam 555 0100');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Wallet details'), findsOneWidget);
    expect(find.text('Sam 555 0100'), findsOneWidget);
    expect(find.textContaining('Could not save'), findsOneWidget);

    store.failWrites = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Wallet details'), findsNothing);
    expect(health.wallet.emergencyContact, 'Sam 555 0100');
  });

  testWidgets('the dial-it-yourself dialog scrolls at large text sizes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(3.0)),
          child: child!,
        ),
        home: HelpNowScreen(
          config: const HelpNowConfig(),
          launcher: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Help Now itself fits');
    final poison = find.text('Poison Control');
    await tester.scrollUntilVisible(poison, 200);
    await tester.pumpAndSettle();
    await tester.tap(poison);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'no overflow');
    expect(find.text('Dial this number'), findsOneWidget);
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.byType(SingleChildScrollView)),
      findsWidgets,
    );
    expect(find.text('Copy number'), findsOneWidget);
  });
}
