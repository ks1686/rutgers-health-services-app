import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/nearby/data/device_location.dart';
import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';

class _ScriptedLocation implements DeviceLocationSource {
  _ScriptedLocation(this.outcome);

  final DeviceLocationOutcome outcome;
  int calls = 0;

  @override
  Future<DeviceLocationOutcome> getCurrent() async {
    calls++;
    return outcome;
  }
}

void main() {
  test('ok outcome carries the fix as a GeoPoint', () async {
    final source = _ScriptedLocation(
      DeviceLocationOk(const GeoPoint(lat: 40.5, lng: -74.4)),
    );

    final outcome = await source.getCurrent();

    expect(outcome, isA<DeviceLocationOk>());
    final ok = outcome as DeviceLocationOk;
    expect(ok.point.lat, 40.5);
    expect(ok.point.lng, -74.4);
  });

  test('soft-fail carries its reason without throwing', () async {
    for (final reason in DeviceLocationFailure.values) {
      final source = _ScriptedLocation(DeviceLocationSoftFail(reason));

      final outcome = await source.getCurrent();

      final fail = outcome as DeviceLocationSoftFail;
      expect(fail.reason, reason);
    }
  });

  test('source is asked exactly once per lookup (one-shot contract)', () async {
    final source = _ScriptedLocation(
      DeviceLocationSoftFail(DeviceLocationFailure.unavailable),
    );

    await source.getCurrent();
    await source.getCurrent();

    expect(source.calls, 2);
  });
}
