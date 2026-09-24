import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store_factory.dart';
import 'package:cwc_health_app/features/my_health/data/prefs_health_store.dart';
import 'package:cwc_health_app/features/my_health/data/secure_health_store.dart';
import 'package:cwc_health_app/features/my_health/data/secure_string_store.dart';

void main() {
  final sample = HealthSnapshot(
    appointments: [
      HealthAppointment(
        id: 'a1',
        provider: 'Dr. Rivera',
        whenLabel: 'Thu, Aug 7 · 10:30 AM',
        location: 'Clinic',
        phone: '(732) 555-0198',
      ),
    ],
    initialized: true,
  );

  test('secure health store round-trips', () async {
    final store = SecureHealthStore(MemorySecureStringStore());
    await store.write(sample);
    final loaded = await store.read();
    expect(loaded.appointments.single.provider, 'Dr. Rivera');
    expect(loaded.documents, isEmpty);
    expect(loaded.initialized, isTrue);

    await store.write(
      sample.copyWith(
        documents: const [
          HealthDocument(
            id: 'd1',
            kind: HealthDocumentKind.livingWill,
            title: 'Living will',
            body: 'My wishes.',
          ),
        ],
      ),
    );
    final withPaper = await store.read();
    expect(withPaper.documents.single.kind, HealthDocumentKind.livingWill);
    expect(withPaper.documents.single.body, 'My wishes.');
  });

  test('migrates plaintext prefs into secure store and wipes prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PrefsHealthStore(prefs).write(sample);
    expect(prefs.getString(PrefsHealthStore.dataKey), isNotNull);

    final memory = MemorySecureStringStore();
    final secure = SecureHealthStore(memory);
    await HealthStoreFactory.migrateLegacyPrefsIfNeeded(
      secure: secure,
      prefs: prefs,
    );

    expect(prefs.getString(PrefsHealthStore.dataKey), isNull);
    expect((await secure.read()).appointments.single.provider, 'Dr. Rivera');
  });

  test(
    'does not overwrite initialized secure data when wiping legacy',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await PrefsHealthStore(prefs).write(sample);

      final memory = MemorySecureStringStore();
      final secure = SecureHealthStore(memory);
      await secure.write(
        const HealthSnapshot(
          medications: [
            HealthMedication(
              id: 'm1',
              name: 'Already secure',
              purpose: 'Test',
              schedule: 'Once',
            ),
          ],
          initialized: true,
        ),
      );

      await HealthStoreFactory.migrateLegacyPrefsIfNeeded(
        secure: secure,
        prefs: prefs,
      );

      expect(prefs.getString(PrefsHealthStore.dataKey), isNull);
      expect((await secure.read()).medications.single.name, 'Already secure');
      expect((await secure.read()).appointments, isEmpty);
    },
  );
}
