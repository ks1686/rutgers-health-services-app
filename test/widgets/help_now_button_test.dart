import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:cwc_health_app/widgets/help_now_button.dart';

void main() {
  testWidgets('Help Now pill is at least 48 dp tall', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: Scaffold(appBar: AppBar(actions: const [HelpNowButton()])),
      ),
    );
    final size = tester.getSize(find.widgetWithText(FilledButton, 'Help Now'));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
