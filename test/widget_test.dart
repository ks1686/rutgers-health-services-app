import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/data/content_catalog.dart';
import 'package:cwc_health_app/features/learn/learn_screen.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/nearby/widgets/nearby_coverage_notice.dart';
import 'package:cwc_health_app/features/onboarding/disclaimer_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadLearnTopics();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> prefs = const {disclaimerAckPref: true},
  }) async {
    SharedPreferences.setMockInitialValues(Map<String, Object>.from(prefs));
    final health = HealthController(InMemoryHealthStore());
    await health.load();
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(CwcApp(healthController: health));
    await tester.pumpAndSettle();
  }

  testWidgets('cold start lands on My Health after disclaimer', (tester) async {
    await pumpApp(tester);

    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('Help Now'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.text('Nearby').last);
    await tester.pumpAndSettle();
    expect(find.text('Main Street Pharmacy'), findsOneWidget);
  });

  testWidgets('first launch shows disclaimer until acknowledged', (
    tester,
  ) async {
    await pumpApp(tester, prefs: const {});

    expect(find.text('Before you continue'), findsOneWidget);
    expect(find.textContaining('call 911'), findsOneWidget);
    expect(find.textContaining('not a substitute'), findsOneWidget);
    expect(find.textContaining('healthcare providers'), findsOneWidget);
    expect(find.text('Appointments'), findsNothing);

    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    expect(find.text('Appointments'), findsOneWidget);
  });

  testWidgets('shell shows Nearby and Help Now', (tester) async {
    await pumpApp(tester);

    expect(find.text('Nearby'), findsWidgets);
    expect(find.text('Help Now'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);

    await tester.tap(find.text('My Health').last);
    await tester.pumpAndSettle();
    expect(find.text('Appointments'), findsOneWidget);

    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text('Physical Health'), findsOneWidget);

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    expect(find.text('Ask a Peer'), findsOneWidget);

    await tester.tap(find.text('Help Now'));
    await tester.pumpAndSettle();
    expect(find.text("You're not alone"), findsOneWidget);
    expect(find.text('911 Emergency'), findsOneWidget);
  });

  testWidgets('Learn article and wallet card open', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Physical Health'));
    await tester.pumpAndSettle();
    expect(find.text('From: CDC'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Health').last);
    await tester.pumpAndSettle();
    final walletButton = find.text('Show My Wallet Card');
    await tester.scrollUntilVisible(walletButton, 300);
    await tester.pumpAndSettle();
    expect(walletButton, findsOneWidget);
    await tester.tap(walletButton);
    await tester.pumpAndSettle();
    expect(find.text('My Health Snapshot'), findsOneWidget);
  });

  testWidgets('bottom tabs render with stable keys', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(const ValueKey('tab-nearby')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-my-health')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-learn')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-more')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Nearby filters, map placeholder, and demo actions render', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Nearby').last);
    await tester.pumpAndSettle();

    expect(find.text('New Brunswick ▾'), findsOneWidget);
    expect(find.text('Use my location?'), findsOneWidget);
    expect(find.text('See these on a map'), findsOneWidget);

    await tester.tap(find.text('Pharmacy'));
    await tester.pumpAndSettle();
    expect(find.text('Main Street Pharmacy'), findsOneWidget);
    expect(find.text('Community Health Clinic'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Community Health Clinic'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('Map view placeholder'), findsOneWidget);

    await tester.tap(find.text('Call').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo only'), findsOneWidget);
  });

  testWidgets('disclaimers stay on Learn, More, and Nearby', (tester) async {
    await pumpApp(tester);

    expect(find.text(kLearnDoctorDisclaimer), findsNothing);
    expect(find.text(kNearbyCoverageWarning), findsNothing);
    expect(find.text('About this app'), findsNothing);

    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text(kLearnDoctorDisclaimer), findsOneWidget);
    expect(find.text(kNearbyCoverageWarning), findsNothing);

    await tester.tap(find.text('Nearby').last);
    await tester.pumpAndSettle();
    expect(find.text(kNearbyCoverageWarning), findsOneWidget);
    expect(find.text(kLearnDoctorDisclaimer), findsNothing);

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    expect(find.text('About this app'), findsOneWidget);
    expect(find.text(kNearbyCoverageWarning), findsNothing);

    await tester.tap(find.text('About this app'));
    await tester.pumpAndSettle();
    expect(find.text(kLearnDoctorDisclaimer), findsNothing);
    expect(
      find.textContaining('does not replace professional care'),
      findsOneWidget,
    );
    expect(find.textContaining('stays on this phone'), findsOneWidget);
    expect(find.textContaining('public maps'), findsOneWidget);
  });

  testWidgets('Help Now stays reachable from every tab', (tester) async {
    await pumpApp(tester);

    Future<void> openHelpNowAndBack() async {
      await tester.tap(find.text('Help Now'));
      await tester.pumpAndSettle();
      expect(find.text("You're not alone"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    }

    await openHelpNowAndBack();

    for (final tab in ['My Health', 'Learn', 'More', 'Nearby']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      await openHelpNowAndBack();
    }
  });

  testWidgets('My Health offers optional PIN without claiming it by default', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('My Health').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Protected by your PIN'), findsNothing);
    expect(find.textContaining('encrypted on this phone'), findsOneWidget);
    expect(find.text('Set PIN'), findsOneWidget);
  });

  testWidgets('Erase confirms and clears stored My Health data', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erase My Information'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Erase'));
    await tester.pumpAndSettle();
    expect(find.textContaining('was erased'), findsOneWidget);
  });
}
