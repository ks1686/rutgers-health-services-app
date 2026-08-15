import 'package:cwc_health_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const CwcApp());
    await tester.pumpAndSettle();
  }

  testWidgets('shell shows Nearby and Help Now', (tester) async {
    await pumpApp(tester);

    expect(find.text('Nearby'), findsWidgets);
    expect(find.text('Help Now'), findsOneWidget);
    expect(find.text('Main Street Pharmacy'), findsOneWidget);

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
    expect(find.text('988 Suicide & Crisis Lifeline'), findsOneWidget);
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
    expect(find.text('Show My Wallet Card'), findsOneWidget);
    await tester.tap(find.text('Show My Wallet Card'));
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

  testWidgets('My Health banner does not claim a PIN', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('My Health').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Protected by your PIN'), findsNothing);
    expect(find.textContaining('does not lock My Health'), findsOneWidget);
  });

  testWidgets('Erase explains nothing is stored', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erase My Information'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing to erase'), findsOneWidget);
  });
}
