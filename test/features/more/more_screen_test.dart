import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/more/about_this_app_page.dart';
import 'package:cwc_health_app/features/more/more_screen.dart';
import 'package:cwc_health_app/features/more/protects_you_page.dart';
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

  testWidgets('Erase dialog mentions Ask a Peer contacts on this phone', (
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

    await tester.scrollUntilVisible(find.text('Erase My Information'), 300);
    await tester.tap(find.text('Erase My Information'));
    await tester.pumpAndSettle();

    expect(find.text('Erase my information?'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Ask a Peer'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('cannot be undone'), findsOneWidget);
  });

  testWidgets('How this app protects you explains on-phone storage', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: const Scaffold(body: MoreScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('How This App Protects You'),
      300,
    );
    await tester.tap(find.text('How This App Protects You'));
    await tester.pumpAndSettle();

    for (final paragraph in kProtectsYouParagraphs) {
      expect(find.text(paragraph), findsOneWidget);
    }
    expect(find.textContaining('not uploaded'), findsOneWidget);
    expect(find.textContaining('does not save a trail'), findsOneWidget);
  });
}
