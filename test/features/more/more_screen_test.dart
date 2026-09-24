import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/more/about_this_app_page.dart';
import 'package:cwc_health_app/features/more/more_screen.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';

void main() {
  testWidgets('About this app opens the general disclaimer again', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: const Scaffold(body: MoreScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About this app'), findsOneWidget);
    await tester.tap(find.text('About this app'));
    await tester.pumpAndSettle();

    for (final paragraph in kAboutThisAppParagraphs) {
      expect(find.text(paragraph), findsOneWidget);
    }
  });
}
