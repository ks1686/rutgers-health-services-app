import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwc_health_app/features/nearby/data/opening_hours.dart';
import 'package:cwc_health_app/features/nearby/widgets/nearby_hours_control.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';

const _week = [
  'Monday 9:00 AM – 7:00 PM',
  'Tuesday 9:00 AM – 7:00 PM',
  'Wednesday 9:00 AM – 7:00 PM',
  'Thursday 9:00 AM – 7:00 PM',
  'Friday 9:00 AM – 7:00 PM',
  'Saturday 9:00 AM – 5:00 PM',
  'Sunday 10:00 AM – 4:00 PM',
];

void main() {
  Future<void> pump(WidgetTester tester, OpeningHoursView view) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: Scaffold(body: NearbyHoursControl(view: view)),
      ),
    );
  }

  testWidgets('unknown is plain Hours not listed, not a button', (
    tester,
  ) async {
    await pump(tester, const OpeningHoursView(kind: OpeningHoursKind.unknown));

    expect(find.text('Hours not listed'), findsOneWidget);
    expect(find.text('Open now'), findsNothing);
    expect(find.text('Closed'), findsNothing);
    expect(find.byTooltip('Open now, show hours'), findsNothing);
    expect(
      tester.getSize(find.text('Hours not listed')).height,
      greaterThanOrEqualTo(18),
    );
  });

  testWidgets('open now starts collapsed and expands then collapses', (
    tester,
  ) async {
    await pump(
      tester,
      const OpeningHoursView(
        kind: OpeningHoursKind.openNow,
        weekdayLines: _week,
      ),
    );

    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('Monday 9:00 AM – 7:00 PM'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Open now, show hours'));
    await tester.pumpAndSettle();

    expect(find.text('Monday 9:00 AM – 7:00 PM'), findsOneWidget);
    expect(find.text('Sunday 10:00 AM – 4:00 PM'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Open now, hide hours'));
    await tester.pumpAndSettle();

    expect(find.text('Monday 9:00 AM – 7:00 PM'), findsNothing);
  });

  testWidgets('closed expands the same week list', (tester) async {
    await pump(
      tester,
      const OpeningHoursView(
        kind: OpeningHoursKind.closed,
        weekdayLines: _week,
      ),
    );

    expect(find.text('Closed'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Closed, show hours'));
    await tester.pumpAndSettle();
    expect(find.text('Monday 9:00 AM – 7:00 PM'), findsOneWidget);
  });
}
