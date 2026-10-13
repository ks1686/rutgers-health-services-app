import 'package:cwc_health_app/features/help_now/help_now_config.dart';
import 'package:cwc_health_app/features/help_now/help_now_screen.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/my_health/health_scope.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHelpNow(
    WidgetTester tester,
    Widget home, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme: buildCwcTheme(), home: home));
    await tester.pumpAndSettle();
  }

  test('calling is on by default and unconfirmed rows are off', () {
    final config = HelpNowConfig.fromEnvironment();
    expect(config.liveCalls, isTrue);
    expect(config.showUnconfirmedRows, isFalse);
  });

  testWidgets('unconfirmed warmline and wellness center rows stay hidden', (
    tester,
  ) async {
    await pumpHelpNow(tester, const HelpNowScreen());
    await tester.scrollUntilVisible(
      find.text('NJ Self-Help Group Clearinghouse'),
      200,
    );
    expect(find.text('NJ Peer Warmline'), findsNothing);
    expect(find.text('My Wellness Center'), findsNothing);
  });

  testWidgets('the banner explains the number is filled in, not dialed', (
    tester,
  ) async {
    await pumpHelpNow(tester, const HelpNowScreen());
    expect(find.textContaining('never dials for you'), findsOneWidget);
    expect(find.textContaining('demo'), findsNothing);
  });

  testWidgets('911 sits above 988 and the emergency card sits above 911', (
    tester,
  ) async {
    await pumpHelpNow(tester, const HelpNowScreen());

    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Additional support'), findsOneWidget);

    final card = tester.getTopLeft(find.text('Show my emergency card here'));
    final nineOneOne = tester.getTopLeft(find.text('911 Emergency'));
    final nineEight = tester.getTopLeft(find.text('Call 988'));
    expect(card.dy, lessThan(nineOneOne.dy));
    expect(nineOneOne.dy, lessThan(nineEight.dy));
  });

  testWidgets('flag-on 988 splits call and text and launches tel/sms', (
    tester,
  ) async {
    final launched = <Uri>[];
    await pumpHelpNow(
      tester,
      HelpNowScreen(
        config: const HelpNowConfig(),
        launcher: (uri) async {
          launched.add(uri);
          return true;
        },
      ),
    );
    await tester.scrollUntilVisible(find.text('Call 988'), 200);
    await tester.tap(find.text('Call 988'));
    await tester.pumpAndSettle();
    expect(launched.single.scheme, 'tel');
    launched.clear();
    await tester.tap(find.text('Text 988'));
    await tester.pumpAndSettle();
    expect(launched.single.scheme, 'sms');
  });

  testWidgets('flag-on 911, Poison Control, and ReachNJ launch tel', (
    tester,
  ) async {
    final launched = <Uri>[];
    await pumpHelpNow(
      tester,
      HelpNowScreen(
        config: const HelpNowConfig(),
        launcher: (uri) async {
          launched.add(uri);
          return true;
        },
      ),
    );

    await tester.tap(find.text('911 Emergency'));
    await tester.pumpAndSettle();
    expect(launched.single, Uri(scheme: 'tel', path: '911'));
    launched.clear();

    await tester.scrollUntilVisible(find.text('Poison Control'), 300);
    await tester.tap(find.text('Poison Control'));
    await tester.pumpAndSettle();
    expect(launched.single, Uri(scheme: 'tel', path: '18002221222'));
    launched.clear();

    await tester.scrollUntilVisible(find.text('ReachNJ'), 300);
    await tester.tap(find.text('ReachNJ'));
    await tester.pumpAndSettle();
    expect(launched.single, Uri(scheme: 'tel', path: '18447322465'));
  });

  testWidgets('revealing unconfirmed rows still cannot dial them', (
    tester,
  ) async {
    final launched = <Uri>[];
    await pumpHelpNow(
      tester,
      HelpNowScreen(
        config: const HelpNowConfig(showUnconfirmedRows: true),
        launcher: (uri) async {
          launched.add(uri);
          return true;
        },
      ),
    );

    await tester.scrollUntilVisible(find.text('NJ Peer Warmline'), 400);
    await tester.tap(find.text('NJ Peer Warmline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sample number'), findsWidgets);
    expect(
      find.textContaining('not available yet'),
      findsOneWidget,
      reason: 'an unconfirmed number must not open a dialer',
    );

    await tester.tap(find.text('My Wellness Center'));
    await tester.pumpAndSettle();
    expect(launched, isEmpty);
  });

  testWidgets('emergency card preview uses the real My Health wallet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final health = HealthController(InMemoryHealthStore());
    await health.load();
    await health.updateWallet(
      const HealthWallet(
        emergencyContact: 'Jordan P. · (609) 555-0199',
        conditions: 'Asthma',
      ),
    );
    await health.updateEmergencyCard(
      const EmergencyCardChoices(
        showEmergencyContact: true,
        showConditions: true,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: HealthScope(
          controller: health,
          child: const HelpNowScreen(config: HelpNowConfig(liveCalls: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jordan P.'), findsOneWidget);
    expect(find.textContaining('Asthma'), findsOneWidget);
    expect(find.textContaining('Sertraline'), findsNothing);
    expect(find.textContaining('Metformin'), findsNothing);
    expect(
      find.textContaining('Emergency card preview (sample)'),
      findsNothing,
    );
    expect(find.textContaining('Alex M.'), findsNothing);
  });

  testWidgets('turning the card on shares nothing until a field is chosen', (
    tester,
  ) async {
    final health = HealthController(InMemoryHealthStore());
    await health.load();
    await health.setPin('1234');
    health.lock();

    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: HealthScope(
          controller: health,
          child: const HelpNowScreen(config: HelpNowConfig(liveCalls: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(health.isUnlocked, isFalse);
    expect(find.textContaining('Nothing from My Health'), findsOneWidget);
    expect(find.textContaining('Sertraline'), findsNothing);
    expect(find.textContaining('Alex M.'), findsNothing);
    expect(find.textContaining('Diabetes'), findsNothing);
  });

  testWidgets('large text keeps 48dp targets and semantics labels', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildCwcTheme(),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaler: const TextScaler.linear(2)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const HelpNowScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      const labels = <String>[
        'Call 911, emergency. Opens your phone dialer.',
        'Call 988. Opens your phone dialer.',
        'Text 988. Opens your phone messages.',
        'Call Poison Control. Opens your phone dialer.',
        'Call ReachNJ. Opens your phone dialer.',
        'Call NJ Self-Help Group Clearinghouse. Opens your phone dialer.',
      ];

      for (final label in labels) {
        final finder = find.bySemanticsLabel(label);
        await tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(finder, findsOneWidget);
        final size = tester.getSize(finder);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
      }

      final card = find.text('Show my emergency card here');
      await tester.scrollUntilVisible(
        card,
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      final tile = find.ancestor(
        of: card,
        matching: find.byType(SwitchListTile),
      );
      final tileSize = tester.getSize(tile);
      expect(tileSize.height, greaterThanOrEqualTo(48));
      expect(tileSize.width, greaterThanOrEqualTo(48));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
