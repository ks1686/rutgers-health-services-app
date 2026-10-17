import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/visible_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const snapshot = HealthSnapshot(
    medications: [
      HealthMedication(
        id: 'med-1',
        name: 'Metformin',
        purpose: 'Diabetes',
        schedule: 'morning',
      ),
    ],
    providers: [
      HealthProvider(
        id: 'p1',
        name: 'Dr. Rivera',
        role: 'Primary care',
        phone: '7325550100',
      ),
    ],
    wallet: HealthWallet(emergencyContact: 'Jordan P.'),
  );

  test('helper mode empties every list and the wallet', () {
    final visible = VisibleHealth(snapshot: snapshot, hidden: true);
    expect(visible.medications, isEmpty);
    expect(visible.providers, isEmpty);
    expect(visible.appointments, isEmpty);
    expect(visible.documents, isEmpty);
    expect(visible.wallet.emergencyContact, isEmpty);
  });

  test('records pass through when helper mode is off', () {
    final visible = VisibleHealth(snapshot: snapshot, hidden: false);
    expect(visible.medications.single.name, 'Metformin');
    expect(visible.providers.single.name, 'Dr. Rivera');
    expect(visible.wallet.emergencyContact, 'Jordan P.');
  });
}
