import 'package:cwc_health_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shell shows Nearby and Help Now', (tester) async {
    await tester.pumpWidget(const CwcApp());

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
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CwcApp());

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
}
