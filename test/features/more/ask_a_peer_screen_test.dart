import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/more/peer_contact.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_launchers.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/onboarding/disclaimer_prefs.dart';
import 'package:cwc_health_app/features/settings/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(
    WidgetTester tester, {
    required List<Uri> launched,
  }) async {
    SharedPreferences.setMockInitialValues({disclaimerAckPref: true});
    final health = HealthController(InMemoryHealthStore());
    await health.load();
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CwcApp(
        healthController: health,
        linkLauncher: (uri) async {
          launched.add(uri);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAsk(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ask a Peer'), 300);
    await tester.tap(find.text('Ask a Peer'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty Ask a Peer prompts to add someone and shows no sample number',
    (tester) async {
      await pumpApp(tester, launched: []);
      await openAsk(tester);

      expect(
        find.textContaining('No one is saved on this phone yet.'),
        findsOneWidget,
      );
      expect(find.textContaining('would appear here'), findsNothing);
      expect(find.textContaining('555'), findsNothing);
      expect(find.text('NJ Peer Warmline'), findsNothing);
      expect(find.text('Add a contact'), findsOneWidget);
    },
  );

  testWidgets('saved contacts can be called, edited, and removed', (
    tester,
  ) async {
    final launched = <Uri>[];
    await pumpApp(tester, launched: launched);
    await openAsk(tester);

    await tester.tap(find.byKey(const ValueKey('add-peer-contact')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('peer-name')), 'Sam');
    await tester.enterText(
      find.byKey(const ValueKey('peer-phone')),
      '(732) 555-0100',
    );
    await tester.tap(find.byKey(const ValueKey('save-peer-contact')));
    await tester.pumpAndSettle();

    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('(732) 555-0100'), findsOneWidget);
    await tester.tap(find.text('Call'));
    await tester.pumpAndSettle();
    expect(launched.single, healthTelUri('(732) 555-0100'));

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('peer-name')), 'Jordan');
    await tester.enterText(find.byKey(const ValueKey('peer-phone')), '');
    await tester.enterText(
      find.byKey(const ValueKey('peer-reach')),
      'In person at the center',
    );
    await tester.tap(find.byKey(const ValueKey('save-peer-contact')));
    await tester.pumpAndSettle();

    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('In person at the center'), findsOneWidget);
    expect(find.text('Call'), findsNothing);
    expect(find.text('Text'), findsNothing);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Jordan'), findsNothing);
    expect(
      find.textContaining('No one is saved on this phone yet.'),
      findsOneWidget,
    );
  });

  testWidgets('save stays put until there is a name and a way to reach them', (
    tester,
  ) async {
    await pumpApp(tester, launched: []);
    await openAsk(tester);
    await tester.tap(find.byKey(const ValueKey('add-peer-contact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-peer-contact')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Add a name'), findsOneWidget);
    expect(find.text('Add a contact'), findsOneWidget);
  });

  testWidgets('Erase my information also clears saved Ask a Peer contacts', (
    tester,
  ) async {
    await pumpApp(tester, launched: []);
    await openAsk(tester);

    await tester.tap(find.byKey(const ValueKey('add-peer-contact')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('peer-name')), 'Sam');
    await tester.enterText(
      find.byKey(const ValueKey('peer-phone')),
      '(732) 555-0100',
    );
    await tester.tap(find.byKey(const ValueKey('save-peer-contact')));
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Erase My Information'), 300);
    await tester.tap(find.text('Erase My Information'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Ask a Peer'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Erase'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Your information was erased from this phone'),
      findsOneWidget,
    );

    final stored = await SharedPreferences.getInstance();
    expect(
      peerContactsFromStored(stored.getString(kPeerContactsPref)),
      isEmpty,
    );

    await tester.tap(find.text('Ask a Peer'));
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsNothing);
    expect(
      find.textContaining('No one is saved on this phone yet.'),
      findsOneWidget,
    );
  });
}
