import 'package:cwc_health_app/features/onboarding/disclaimer_screen.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// C1: the care warning shows on every cold start, so it must never trap a
/// person who uses large text. A RenderFlex overflow is reported as a test
/// failure by the framework, and the buttons must stay on screen.
void main() {
  const size = Size(360, 640);
  const scales = [1.0, 1.25, 1.3, 1.5, 1.75, 2.0];

  Future<bool> pumpAt(WidgetTester tester, double scale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var acknowledged = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: DisclaimerScreen(
          launcher: (_) async => true,
          onAcknowledged: () => acknowledged = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final understand = find.text('I understand');
    expect(understand, findsOneWidget);
    final rect = tester.getRect(understand);
    expect(
      rect.bottom,
      lessThanOrEqualTo(size.height),
      reason: '"I understand" must be on screen at text scale $scale',
    );
    for (final label in ['Call 911', 'Call 988']) {
      final button = find.text(label);
      expect(button, findsOneWidget, reason: label);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(size.height));
    }
    await tester.tap(understand);
    await tester.pump();
    return acknowledged;
  }

  for (final scale in scales) {
    testWidgets('360x640 at text scale $scale: no overflow, buttons reachable', (
      tester,
    ) async {
      expect(await pumpAt(tester, scale), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('long body text scrolls at text scale 2.0', (tester) async {
    await pumpAt(tester, 2.0);
    final scrollable = find.byType(Scrollable);
    expect(scrollable, findsWidgets);
    await tester.dragUntilVisible(
      find.text('Read the full agreement in More'),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Read the full agreement in More'), findsOneWidget);
  });
}
