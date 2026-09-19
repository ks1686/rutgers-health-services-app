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

  test('HELP_NOW_LIVE defaults off', () {
    final config = HelpNowConfig.fromEnvironment();
    expect(config.helpNowLive, isFalse);
  });

  testWidgets('flag-off Help Now stays demo-only', (tester) async {
    await pumpHelpNow(
      tester,
      const HelpNowScreen(config: HelpNowConfig(helpNowLive: false)),
    );
    await tester.tap(find.text('988 Suicide & Crisis Lifeline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo only'), findsOneWidget);
  });

  testWidgets('911 sits above 988 and the emergency card sits above 911', (
    tester,
  ) async {
    await pumpHelpNow(
      tester,
      const HelpNowScreen(config: HelpNowConfig(helpNowLive: false)),
    );

    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Additional support'), findsOneWidget);

    final card = tester.getTopLeft(find.text('Show my emergency card here'));
    final nineOneOne = tester.getTopLeft(find.text('911 Emergency'));
    final nineEight = tester.getTopLeft(
      find.text('988 Suicide & Crisis Lifeline'),
    );
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
        config: const HelpNowConfig(helpNowLive: true),
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
        config: const HelpNowConfig(helpNowLive: true),
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

  testWidgets('warmline and CWC stay demo even when live', (tester) async {
    final launched = <Uri>[];
    await pumpHelpNow(
      tester,
      HelpNowScreen(
        config: const HelpNowConfig(helpNowLive: true),
        launcher: (uri) async {
          launched.add(uri);
          return true;
        },
      ),
    );

    await tester.scrollUntilVisible(find.text('NJ Peer Warmline'), 400);
    await tester.tap(find.text('NJ Peer Warmline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo only'), findsOneWidget);
    expect(find.textContaining('sample number'), findsWidgets);

    await tester.tap(find.text('My Wellness Center'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo only'), findsWidgets);
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

    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: HealthScope(
          controller: health,
          child: const HelpNowScreen(config: HelpNowConfig(helpNowLive: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jordan P.'), findsOneWidget);
    expect(find.textContaining('Asthma'), findsOneWidget);
    expect(
      find.textContaining('Emergency card preview (sample)'),
      findsNothing,
    );
    expect(find.textContaining('Alex M.'), findsNothing);
  });
}
