import 'package:cwc_health_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end smoke of shell navigation and critical chrome.
///
/// Runs in CI via `flutter test integration_test` (VM) and can be driven on
/// devices/web with `flutter drive` when needed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full tab circuit and Help Now', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CwcApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tab-nearby')), findsOneWidget);
    expect(find.text('Main Street Pharmacy'), findsOneWidget);
    expect(find.text('Help Now'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.text('Appointments'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-learn')));
    await tester.pumpAndSettle();
    expect(find.text('Physical Health'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    expect(find.text('Ask a Peer'), findsOneWidget);
    expect(find.text('Erase My Information'), findsOneWidget);

    await tester.tap(find.text('Help Now'));
    await tester.pumpAndSettle();
    expect(find.text("You're not alone"), findsOneWidget);
    expect(find.text('988 Suicide & Crisis Lifeline'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tab-nearby')));
    await tester.pumpAndSettle();
    expect(find.text('Main Street Pharmacy'), findsOneWidget);
  });
}
