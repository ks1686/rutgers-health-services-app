import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/data/demo_learn.dart';
import 'package:cwc_health_app/features/learn/learn_screen.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';

void main() {
  testWidgets('Learn at 2.0 text scale does not overflow', (tester) async {
    FlutterError.onError = (details) {
      if (details.exception is FlutterError &&
          details.exception.toString().contains('overflowed')) {
        fail(details.exception.toString());
      }
      FlutterError.presentError(details);
    };
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: LearnScreen(
            topics: const [
              DemoLearnTopic(
                title: 'Physical Health',
                iconLabel: 'body',
                summary: 'Everyday care for your body.',
                body: 'Check in with how you feel.',
                source: 'CDC',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Physical Health'), findsOneWidget);
  });

  testWidgets('Learn loads topics from the injected loader', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: Scaffold(
          body: LearnScreen(
            topicsLoader: () async => const [
              DemoLearnTopic(
                title: 'Nutrition',
                iconLabel: 'food',
                summary: 'Simple ideas for eating well.',
                body: 'Aim for regular meals when you can.',
                source: 'USDA',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Loading topics…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('This does not replace seeing a doctor.'), findsOneWidget);
  });

  testWidgets('Sleep is its own area and stress stays inside Physical Health', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: const Scaffold(body: LearnScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This does not replace seeing a doctor.'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Stress management'), findsNothing);

    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    expect(find.text('Everyday sleep tips'), findsOneWidget);
    expect(find.text('Sleep apnea'), findsOneWidget);
    expect(find.text('Stress management'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Physical Health'));
    await tester.pumpAndSettle();
    expect(find.text('From: CDC'), findsOneWidget);
    expect(find.text('Stress management'), findsOneWidget);
    expect(find.text('Sleep apnea'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Everyday ways to ease stress'),
      200,
    );
    await tester.tap(find.text('Everyday ways to ease stress'));
    await tester.pumpAndSettle();
    expect(find.textContaining('do not have to track'), findsOneWidget);
    expect(find.text('Read more on MedlinePlus'), findsOneWidget);
  });
}
