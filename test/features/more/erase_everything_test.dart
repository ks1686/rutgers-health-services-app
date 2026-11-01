import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/stub_nearby.dart';

/// M1. Every personal key the app can write, with a value, plus the
/// settings Erase is meant to keep. Literal keys on purpose, so a renamed
/// constant cannot quietly make this test pass.
const _personal = <String, Object>{
  'cwc_peer_contacts': '[{"name":"Sam","phone":"7325550100"}]',
  'cwc_session_answers': '{"q1":{"answer":"yes","note":"x"}}',
  'nearby.v1.place.town': 'Camden',
  'nearby.v1.place.region': 'south',
  'nearby.v1.favoriteIds': <String>['stub-Saved Pharmacy'],
  'nearby.v1.result.camden|NJ': '{"items":[]}',
  'nearby.v1.point.camden|NJ': '{"lat":39.9,"lng":-75.1}',
  'cwc_help_now_show_emergency_card': true,
  'health.v1.snapshot': '{"initialized":true}',
};

const _settings = <String, Object>{
  'cwc_disclaimer_acknowledged': true,
  'cwc_settings_text_scale': 'large',
  'cwc_settings_helper_hiding': false,
};

void main() {
  testWidgets('M1 Erase my information removes every personal key', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({..._personal, ..._settings});
    final health = HealthController(InMemoryHealthStore());
    await health.load();
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CwcApp(
        healthController: health,
        disclaimerAcknowledged: true,
        nearbyRepository: StubNearbyRepository(result: stubNearbyResult()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Erase My Information'), 300);
    await tester.tap(find.text('Erase My Information'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Erase'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final left = prefs.getKeys();
    final survived = [
      for (final key in _personal.keys)
        if (left.contains(key)) '$key=${prefs.get(key)}',
    ];
    expect(survived, isEmpty, reason: 'personal keys survived Erase');
    for (final key in _settings.keys) {
      expect(left, contains(key), reason: 'Erase should keep $key');
    }
  });
}
