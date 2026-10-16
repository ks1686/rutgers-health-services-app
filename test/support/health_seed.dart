import 'package:cwc_health_app/features/my_health/data/biometric_unlock.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/my_health/data/reminder_scheduler.dart';

/// Builds a controller holding one record of each kind.
///
/// The app ships no sample records, so any test that needs a populated My
/// Health has to say what it is putting there. Values here are obviously
/// fictional and never leave the test directory.
Future<HealthController> seededController({
  ReminderScheduler? reminders,
  HealthStore? store,
  BiometricAuthenticator? biometrics,
}) async {
  final controller = HealthController(
    store ?? InMemoryHealthStore(),
    reminders: reminders,
    biometrics: biometrics,
  );
  await controller.load();

  await controller.upsertAppointment(
    HealthAppointment(
      id: 'test-appt-1',
      provider: 'Test Provider',
      whenLabel: 'Thu, Aug 7 · 10:30 AM',
      location: 'Test Clinic',
      phone: '(555) 010-0000',
      note: 'Test note',
    ),
  );
  await controller.upsertMedication(
    HealthMedication(
      id: 'test-med-1',
      name: 'Test Medicine',
      purpose: 'Test purpose',
      schedule: '1 tablet morning and evening with food',
    ),
  );
  await controller.upsertProvider(
    HealthProvider(
      id: 'test-prov-1',
      name: 'Test Provider',
      role: 'Primary care',
      phone: '(555) 010-0000',
    ),
  );
  await controller.upsertDocument(
    const HealthDocument(
      id: 'test-paper-1',
      kind: HealthDocumentKind.otherPaper,
      title: 'Test Paper',
      body: 'Test paper body',
    ),
  );
  await controller.updateWallet(
    const HealthWallet(
      emergencyContact: 'Test Contact · (555) 010-0000',
      conditions: 'Test condition',
    ),
  );
  return controller;
}
