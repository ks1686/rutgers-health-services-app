import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<HealthController> readyController() async {
    final c = HealthController(InMemoryHealthStore());
    await c.load();
    return c;
  }

  Future<void> pumpHealthApp(
    WidgetTester tester, {
    required HealthController health,
    Future<bool> Function(Uri uri)? launcher,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CwcApp(healthController: health, linkLauncher: launcher),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Add appointment form saves onto the list', (tester) async {
    final health = await readyController();
    await health.eraseAll();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.text('No appointments yet. Tap Add.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Add').first);
    await tester.pumpAndSettle();
    expect(find.text('Add appointment'), findsOneWidget);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(5));
    await tester.enterText(fields.at(0), 'Dr. Kim');
    await tester.enterText(fields.at(1), 'Fri · 11:00 AM');
    await tester.enterText(fields.at(2), 'Clinic');
    await tester.enterText(fields.at(3), '555');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Kim'), findsOneWidget);
    expect(health.appointments.single.provider, 'Dr. Kim');
  });

  testWidgets('provider Call launches tel URI', (tester) async {
    final health = await readyController();
    final launched = <Uri>[];
    await pumpHealthApp(
      tester,
      health: health,
      launcher: (uri) async {
        launched.add(uri);
        return true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Call').first);
    await tester.pumpAndSettle();
    expect(launched, isNotEmpty);
    expect(launched.single.scheme, 'tel');
  });

  testWidgets('wallet card shows live medications', (tester) async {
    final health = await readyController();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    final walletButton = find.text('Show My Wallet Card');
    await tester.scrollUntilVisible(walletButton, 300);
    await tester.pumpAndSettle();
    await tester.tap(walletButton);
    await tester.pumpAndSettle();
    expect(find.text('My Health Snapshot'), findsOneWidget);
    expect(find.textContaining('Metformin'), findsOneWidget);
  });

  testWidgets('PIN lock gates My Health content', (tester) async {
    final health = await readyController();
    expect(await health.setPin('1234'), isTrue);
    health.lock();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.text('My Health is locked'), findsOneWidget);
    expect(find.text('Appointments'), findsNothing);

    await tester.tap(find.text('Enter PIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();
    expect(find.text('Appointments'), findsOneWidget);
  });

  testWidgets('Erase from More clears My Health', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final health = await readyController();
    await pumpHealthApp(tester, health: health);

    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erase My Information'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Erase'));
    await tester.pumpAndSettle();
    expect(find.textContaining('was erased'), findsOneWidget);
    expect(health.appointments, isEmpty);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    expect(find.text('No appointments yet. Tap Add.'), findsOneWidget);
  });

  testWidgets('theme smoke for form fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildCwcTheme(), home: const SizedBox()),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
