import 'package:cwc_health_app/features/help_now/help_now_config.dart';
import 'package:cwc_health_app/features/help_now/help_now_screen.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M2. A phone with no dialer (a tablet, a locked-down work phone) makes
/// url_launcher throw instead of returning false.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Future<bool> Function(Uri) launcher,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: HelpNowScreen(config: const HelpNowConfig(), launcher: launcher),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final failure in <String, Future<bool> Function(Uri)>{
    'throws': (_) async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'),
    'returns false': (_) async => false,
  }.entries) {
    testWidgets('M2 dialer ${failure.key}: the number stays on screen', (
      tester,
    ) async {
      await pump(tester, failure.value);
      await tester.tap(find.text('Call 988'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dial this number'), findsOneWidget);
      expect(find.widgetWithText(SelectableText, '988'), findsOneWidget);
    });
  }

  testWidgets('M2 a failed text shows the number to text', (tester) async {
    await pump(tester, (_) async => throw PlatformException(code: 'x'));
    await tester.tap(find.text('Text 988'));
    await tester.pumpAndSettle();
    expect(find.text('Text this number'), findsOneWidget);
    expect(find.widgetWithText(SelectableText, '988'), findsOneWidget);
  });

  testWidgets('M2 long numbers are shown with dashes', (tester) async {
    await pump(tester, (_) async => false);
    await tester.scrollUntilVisible(find.text('Poison Control'), 300);
    await tester.tap(find.text('Poison Control'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(SelectableText, '1-800-222-1222'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Dial this number'), findsNothing);
  });
}
