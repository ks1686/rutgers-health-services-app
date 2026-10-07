import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/help_now/help_now_config.dart';
import 'package:cwc_health_app/features/help_now/help_now_screen.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/onboarding/disclaimer_prefs.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({disclaimerAckPref: true});
    final health = HealthController(InMemoryHealthStore());
    await health.load();
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(CwcApp(healthController: health));
    await tester.pumpAndSettle();
  }

  testWidgets('settings saves text size and town without a PIN control', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(
      find.text('Text size and town preference will go here.'),
      findsNothing,
    );
    expect(find.text('Set PIN'), findsNothing);
    expect(find.textContaining('My Health tab'), findsOneWidget);

    await tester.tap(find.text('Extra large'));
    await tester.pumpAndSettle();
    final scaler = MediaQuery.textScalerOf(
      tester.element(find.text('Save town')),
    );
    expect(scaler.scale(16), 24);

    await tester.enterText(
      find.byKey(const ValueKey('settings-town')),
      'Trenton',
    );
    await tester.tap(find.byKey(const ValueKey('settings-save-town')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nearby').last);
    await tester.pumpAndSettle();
    expect(find.text('Trenton ▾'), findsOneWidget);
  });

  testWidgets('wellness goals are optional and stay out of Learn', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text('Wellness goals'), findsNothing);
    expect(find.text('Physical Health'), findsOneWidget);
    expect(find.text('Drink water'), findsNothing);

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wellness goals'));
    await tester.pumpAndSettle();

    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('Pause for a breath'), findsOneWidget);
    expect(find.text('A steady bedtime and wake time'), findsOneWidget);
    expect(find.textContaining('not medication'), findsOneWidget);

    Switch water() => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const ValueKey('wellness-water')),
        matching: find.byType(Switch),
      ),
    );
    Switch breath() => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const ValueKey('wellness-breath')),
        matching: find.byType(Switch),
      ),
    );

    expect(water().value, isFalse);
    expect(breath().value, isFalse);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('wellness-water')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    expect(water().value, isTrue);
    expect(breath().value, isFalse);
  });

  testWidgets('helper switch hides real health details and restores them', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Dr. Rivera'), findsWidgets);
    expect(find.text('Sample Patient'), findsNothing);

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Helper Mode'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sample records'), findsOneWidget);
    expect(find.textContaining('sample data'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('helper-hide-switch')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Health').last);
    await tester.pumpAndSettle();
    expect(find.text('Dr. Rivera'), findsNothing);
    expect(find.text('Metformin'), findsNothing);
    expect(
      find.textContaining('Hidden while someone is helping you.'),
      findsWidgets,
    );
    expect(find.text('Sample Patient'), findsNothing);

    final wallet = find.text('Show My Wallet Card');
    await tester.scrollUntilVisible(wallet, 300);
    await tester.tap(wallet);
    await tester.pumpAndSettle();
    expect(find.textContaining('Diabetes'), findsNothing);
    expect(
      find.textContaining('Hidden while someone is helping you.'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('More').last);
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
    await tester.tap(find.text('My Health').last);
    await tester.pumpAndSettle();
    expect(find.text('Dr. Rivera'), findsWidgets);
    expect(find.text('Metformin'), findsOneWidget);
  });

  testWidgets('how-to steps work offline and Ask a Peer stays separate', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    expect(find.text('Ask a Peer'), findsOneWidget);

    await tester.tap(find.text('How to Use This App'));
    await tester.pumpAndSettle();
    expect(find.text('Find a pharmacy'), findsOneWidget);
    expect(
      find.textContaining('Ask a Peer is a separate button'),
      findsOneWidget,
    );
    expect(
      find.text('Your Wellness Center contact would appear here'),
      findsNothing,
    );

    await tester.tap(find.text('Find a pharmacy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 1. Open Nearby'), findsOneWidget);
    expect(find.text('Play captions'), findsOneWidget);
    expect(
      find.textContaining('does not include a video file'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask a Peer'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No one is saved on this phone yet.'),
      findsOneWidget,
    );
    expect(find.textContaining('would appear here'), findsNothing);
  });

  testWidgets('Help Now body text stays at least 18 on the 911 button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: const HelpNowScreen(config: HelpNowConfig(helpNowLive: false)),
      ),
    );
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.text('911 Emergency'));
    expect(label.style!.fontSize! >= 18, isTrue);
    final detail = tester.widget<Text>(
      find.text('Police, fire, or medical emergency'),
    );
    expect(detail.style!.fontSize! >= 18, isTrue);
    expect(detail.style!.color, Colors.white);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('911 Emergency'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(
      button.style!.backgroundColor!.resolve(const <WidgetState>{}),
      CwcColors.neutralEmphasis,
    );
    expect(
      button.style!.minimumSize!.resolve(const <WidgetState>{})!.height >= 48,
      isTrue,
    );
  });
}
