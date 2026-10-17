import 'dart:async';

import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/my_health/data/biometric_unlock.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/onboarding/disclaimer_prefs.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_biometric.dart';
import '../../support/health_seed.dart';
import '../../support/stub_nearby.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<HealthController> readyController() async => seededController();

  Future<void> pumpHealthApp(
    WidgetTester tester, {
    required HealthController health,
    Future<bool> Function(Uri uri)? launcher,
  }) async {
    SharedPreferences.setMockInitialValues({disclaimerAckPref: true});
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CwcApp(
        healthController: health,
        disclaimerAcknowledged: true,
        linkLauncher: launcher,
        // Nearby is always live, so keep this test off the network.
        nearbyRepository: StubNearbyRepository(result: stubNearbyResult()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Add appointment form saves onto the list', (tester) async {
    final health = await readyController();
    await health.eraseAll();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.text('No appointments yet. Tap Add.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Add').first);
    await tester.pumpAndSettle();
    expect(find.text('Add appointment'), findsOneWidget);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(5));
    await tester.enterText(fields.at(0), 'Dr. Kim');
    await tester.enterText(fields.at(1), 'Fri · 11:00 AM');
    await tester.enterText(fields.at(2), 'Clinic');
    await tester.enterText(fields.at(3), '555');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Kim'), findsOneWidget);
    expect(health.appointments.single.provider, 'Dr. Kim');
  });

  testWidgets('provider Call launches tel URI', (tester) async {
    final health = await readyController();
    final launched = <Uri>[];
    await pumpHealthApp(
      tester,
      health: health,
      launcher: (uri) async {
        launched.add(uri);
        return true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Call').first);
    await tester.pumpAndSettle();
    expect(launched, isNotEmpty);
    expect(launched.single.scheme, 'tel');
  });

  testWidgets('wallet card shows live medications', (tester) async {
    final health = await readyController();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    final walletButton = find.text('Show My Wallet Card');
    await tester.scrollUntilVisible(walletButton, 300);
    await tester.pumpAndSettle();
    await tester.tap(walletButton);
    await tester.pumpAndSettle();
    expect(find.text('My Health Snapshot'), findsOneWidget);
    expect(find.textContaining('Test Medicine'), findsOneWidget);
  });

  testWidgets('PIN lock gates My Health content', (tester) async {
    final health = await readyController();
    expect(await health.setPin('1234'), isTrue);
    health.lock();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.text('My Health is locked'), findsOneWidget);
    expect(find.text('Appointments'), findsNothing);

    await tester.tap(find.text('Enter PIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();
    expect(find.text('Appointments'), findsOneWidget);
  });

  testWidgets('Erase from More clears My Health', (tester) async {
    final health = await readyController();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erase My Information'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Ask a Peer'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Erase'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your information was erased from this phone'),
      findsOneWidget,
    );
    expect(health.appointments, isEmpty);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.text('No appointments yet. Tap Add.'), findsOneWidget);
  });

  testWidgets('Add personal paper saves onto My Health', (tester) async {
    final health = await readyController();
    await health.eraseAll();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    final addPaper = find.byKey(const ValueKey('add-personal-paper'));
    await tester.ensureVisible(addPaper);
    await tester.pumpAndSettle();
    await tester.tap(addPaper);
    await tester.pumpAndSettle();
    expect(find.text('Add a paper'), findsOneWidget);

    await tester.ensureVisible(
      find.text('Rapid assessment and treatment plan'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rapid assessment and treatment plan'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'My RAT plan');
    await tester.enterText(fields.at(1), 'People I want called.');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('My RAT plan'), findsOneWidget);
    expect(health.documents.single.kind, HealthDocumentKind.ratPlan);
    expect(health.documents.single.body, 'People I want called.');
  });

  testWidgets('a chosen PAD shows on Help Now while My Health stays locked', (
    tester,
  ) async {
    final health = await readyController();
    await health.eraseAll();
    await health.upsertDocument(
      const HealthDocument(
        id: 'pad-1',
        kind: HealthDocumentKind.pad,
        title: 'My psychiatric advance directive',
        body: 'Do not restrain me.',
      ),
    );
    await health.upsertDocument(
      const HealthDocument(
        id: 'will-1',
        kind: HealthDocumentKind.livingWill,
        title: 'Living will',
        body: 'Private living will words.',
      ),
    );
    await health.upsertMedication(
      const HealthMedication(
        id: 'med-1',
        name: 'Sertraline',
        purpose: 'Mood',
        schedule: 'morning',
      ),
    );
    await health.updateEmergencyCard(
      const EmergencyCardChoices(showPsychiatricAdvanceDirective: true),
    );
    await health.setPin('1234');
    health.lock();

    await pumpHealthApp(tester, health: health);
    expect(find.text('My Health is locked'), findsOneWidget);
    expect(find.text('Do not restrain me.'), findsNothing);
    expect(find.text('Sertraline'), findsNothing);

    await tester.tap(find.text('Help Now'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(health.isUnlocked, isFalse);
    expect(find.textContaining('Do not restrain me.'), findsOneWidget);
    expect(find.textContaining('Private living will words.'), findsNothing);
    expect(find.textContaining('Sertraline'), findsNothing);
  });

  testWidgets('My Health can turn the PAD onto the emergency card', (
    tester,
  ) async {
    final health = await readyController();
    await health.eraseAll();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    final padSwitch = find.widgetWithText(
      SwitchListTile,
      'Psychiatric advance directive',
    );
    await tester.ensureVisible(padSwitch);
    await tester.pumpAndSettle();
    expect(health.emergencyCard.sharesAnything, isFalse);

    await tester.tap(padSwitch);
    await tester.pumpAndSettle();
    expect(health.emergencyCard.showPsychiatricAdvanceDirective, isTrue);
    expect(health.emergencyCard.showMedications, isFalse);
    expect(health.emergencyCard.showAppointmentNotes, isFalse);
  });

  testWidgets('doctor prompt is visible when My Health is unlocked', (
    tester,
  ) async {
    final health = await readyController();
    await health.eraseAll();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pcp-prompt')), findsOneWidget);
    expect(find.text('Check with your doctor first'), findsOneWidget);
    expect(find.textContaining('does not give medical advice'), findsOneWidget);
    expect(find.text('Call my provider'), findsNothing);

    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Check with your doctor first')),
      findsWidgets,
    );
    semantics.dispose();
  });

  testWidgets('Call my provider shows only when a provider is saved', (
    tester,
  ) async {
    final health = await readyController();
    final launched = <Uri>[];
    await pumpHealthApp(
      tester,
      health: health,
      launcher: (uri) async {
        launched.add(uri);
        return true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    final call = find.byKey(const ValueKey('pcp-call'));
    await tester.ensureVisible(call);
    await tester.pumpAndSettle();
    expect(find.text('Call my provider'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pcp-prompt')),
        matching: find.text('Test Provider'),
      ),
      findsNothing,
    );

    await tester.tap(call);
    await tester.pumpAndSettle();
    expect(launched, isNotEmpty);
    expect(launched.last.scheme, 'tel');
    expect(launched.last.path, '5550100000');
  });

  testWidgets('helper mode hides provider details on the doctor prompt', (
    tester,
  ) async {
    final health = await readyController();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Helper Mode'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('helper-hide-switch')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    final prompt = find.byKey(const ValueKey('pcp-prompt'));
    expect(prompt, findsOneWidget);
    expect(find.text('Check with your doctor first'), findsOneWidget);
    expect(find.text('Call my provider'), findsNothing);
    expect(
      find.descendant(
        of: prompt,
        matching: find.textContaining('Test Provider'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: prompt, matching: find.textContaining('555')),
      findsNothing,
    );
    expect(find.text('Add', skipOffstage: false), findsNothing);
    expect(
      find.byKey(const ValueKey('add-personal-paper'), skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('lock view shows PIN only when fingerprint is not available', (
    tester,
  ) async {
    final health = await readyController();
    expect(await health.setPin('1234'), isTrue);
    health.lock();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.text('Use fingerprint'), findsNothing);
    expect(find.text('Use your PIN instead.'), findsNothing);
    expect(find.text('Use fingerprint to open My Health'), findsNothing);
  });

  testWidgets('lock view offers fingerprint and still shows Enter PIN', (
    tester,
  ) async {
    final fake = FakeBiometricAuthenticator(available: true);
    final health = await seededController(biometrics: fake);
    expect(await health.setPin('1234'), isTrue);
    expect(await health.enableBiometricUnlock(), isTrue);
    health.lock();
    final gate = Completer<BiometricResult>();
    fake.pending = gate.future;
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pump();
    expect(find.byKey(const ValueKey('use-fingerprint')), findsOneWidget);
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.byKey(const ValueKey('biometric-fallback')), findsNothing);
    expect(health.isUnlocked, isFalse);

    gate.complete(BiometricResult.success);
    await tester.pumpAndSettle();
    expect(find.text('Appointments'), findsOneWidget);
  });

  testWidgets(
    'fingerprint failure stays locked and PIN still opens My Health',
    (tester) async {
      final fake = FakeBiometricAuthenticator(available: true);
      final health = await seededController(biometrics: fake);
      expect(await health.setPin('1234'), isTrue);
      expect(await health.enableBiometricUnlock(), isTrue);
      health.lock();
      fake.result = BiometricResult.lockout;
      await pumpHealthApp(tester, health: health);

      await tester.tap(find.byKey(const ValueKey('tab-my-health')));
      await tester.pumpAndSettle();
      expect(find.text('Use your PIN instead.'), findsOneWidget);
      expect(find.text('Enter PIN'), findsOneWidget);
      expect(find.text('Appointments'), findsNothing);

      await tester.tap(find.text('Enter PIN'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      await tester.pumpAndSettle();
      expect(find.text('Appointments'), findsOneWidget);
      expect(find.text('Use fingerprint to open My Health'), findsOneWidget);
    },
  );

  testWidgets('theme smoke for form fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildCwcTheme(), home: const SizedBox()),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
