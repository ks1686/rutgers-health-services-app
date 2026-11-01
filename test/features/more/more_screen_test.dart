import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/more/about_this_app_page.dart';
import 'package:cwc_health_app/features/more/more_screen.dart';
import 'package:cwc_health_app/features/more/protects_you_page.dart';
import 'package:cwc_health_app/features/more/using_this_app_page.dart';
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

    expect(find.text('Session questions'), findsNothing);
    expect(find.text('About this app'), findsOneWidget);
    await tester.tap(find.text('About this app'));
    await tester.pumpAndSettle();

    for (final paragraph in kAboutThisAppParagraphs) {
      expect(find.text(paragraph), findsOneWidget);
    }
  });

  testWidgets('Using this app agreement opens the draft', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: const Scaffold(body: MoreScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.text('Using this app (agreement)');
    await tester.scrollUntilVisible(tile, 300);
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text(kUsingThisAppParagraphs.first), findsOneWidget);
    expect(find.text('Using this app'), findsOneWidget);
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
      await tester.scrollUntilVisible(find.text(paragraph), 400);
      expect(find.text(paragraph), findsOneWidget);
    }
    final all = kProtectsYouParagraphs.join(' ');
    expect(all, contains('not uploaded'));
    expect(all, contains('a trail of where you go'));
    // H4: say where a location goes instead of claiming it is never shared.
    expect(all, contains('OpenStreetMap'));
    expect(all, contains('Google Places'));
  });
}
