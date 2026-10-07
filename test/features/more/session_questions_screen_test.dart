import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/more/session_answers.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/onboarding/disclaimer_prefs.dart';
import 'package:cwc_health_app/features/settings/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({disclaimerAckPref: true});
    final health = HealthController(InMemoryHealthStore());
    await health.load();
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(CwcApp(healthController: health));
    await tester.pumpAndSettle();
  }

  Future<void> openQuestions(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Session questions'), 300);
    await tester.tap(find.text('Session questions'));
    await tester.pumpAndSettle();
  }

  testWidgets('Yes and a note stay on this phone', (tester) async {
    await pumpApp(tester);
    await openQuestions(tester);

    expect(find.text('Can you find Nearby vs My Health?'), findsOneWidget);
    expect(find.textContaining('not sent anywhere'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('session-nearby-yes')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('session-note')),
      'Buttons are large.',
    );
    await tester.tap(find.byKey(const ValueKey('session-note-save')));
    await tester.pumpAndSettle();

    final stored = await SharedPreferences.getInstance();
    final answers = sessionAnswersFromStored(
      stored.getString(kSessionAnswersPref),
    );
    expect(answers.nearby, sessionYes);
    expect(answers.note, 'Buttons are large.');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openQuestions(tester);
    expect(find.text('Buttons are large.'), findsOneWidget);
  });

  testWidgets('Erase deletes session answers', (tester) async {
    await pumpApp(tester);
    await openQuestions(tester);
    await tester.tap(find.byKey(const ValueKey('session-help-no')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Erase My Information'), 300);
    await tester.tap(find.text('Erase My Information'));
    await tester.pumpAndSettle();
    expect(find.textContaining('session question answers'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Erase'));
    await tester.pumpAndSettle();

    final stored = await SharedPreferences.getInstance();
    expect(
      sessionAnswersFromStored(stored.getString(kSessionAnswersPref)).isEmpty,
      isTrue,
    );
  });
}
