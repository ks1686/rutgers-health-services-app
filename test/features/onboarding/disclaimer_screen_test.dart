import 'package:cwc_health_app/features/onboarding/disclaimer_screen.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disclaimer covers 911, professional-care limits, and ack', (
    tester,
  ) async {
    var acknowledged = false;
    final launched = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: DisclaimerScreen(
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
          onAcknowledged: () => acknowledged = true,
        ),
      ),
    );

    expect(find.text('Before you continue'), findsOneWidget);
    expect(
      find.textContaining('If this is an emergency, call 911'),
      findsOneWidget,
    );
    expect(find.textContaining('not a substitute'), findsOneWidget);
    expect(find.textContaining('healthcare providers'), findsOneWidget);

    await tester.tap(find.text('Call 911'));
    await tester.pumpAndSettle();
    expect(launched, [Uri(scheme: 'tel', path: '911')]);

    await tester.tap(find.text('I understand'));
    expect(acknowledged, isTrue);
  });
}
