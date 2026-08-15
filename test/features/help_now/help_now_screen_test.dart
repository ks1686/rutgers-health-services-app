import 'package:cwc_health_app/features/help_now/help_now_config.dart';
import 'package:cwc_health_app/features/help_now/help_now_screen.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHelpNow(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme: buildCwcTheme(), home: home));
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
    await tester.tap(find.text('Call 988'));
    await tester.pumpAndSettle();
    expect(launched.single.scheme, 'tel');
    launched.clear();
    await tester.tap(find.text('Text 988'));
    await tester.pumpAndSettle();
    expect(launched.single.scheme, 'sms');
  });

  testWidgets('flag-on 911 and Poison Control launch tel', (tester) async {
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

    await tester.tap(find.text('Poison Control'));
    await tester.pumpAndSettle();
    expect(launched.single, Uri(scheme: 'tel', path: '18002221222'));
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

    await tester.tap(find.text('NJ Peer Warmline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo only'), findsOneWidget);
    expect(find.textContaining('sample number'), findsWidgets);

    await tester.tap(find.text('My Wellness Center'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo only'), findsWidgets);
    expect(launched, isEmpty);
  });
}
