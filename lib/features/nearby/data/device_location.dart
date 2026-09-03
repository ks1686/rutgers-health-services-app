import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'sources/geo_point.dart';

/// Why a one-shot device-location fix could not be produced.
enum DeviceLocationFailure {
  /// The member said no (this session or permanently), or the OS blocks it.
  permissionDenied,

  /// The phone has location services switched off system-wide.
  serviceDisabled,

  /// The fix took too long or the radio failed; worth retrying.
  unavailable,
}

/// Every outcome of asking for the device's location, as plain data.
sealed class DeviceLocationOutcome {}

class DeviceLocationOk extends DeviceLocationOutcome {
  DeviceLocationOk(this.point);

  final GeoPoint point;
}

class DeviceLocationSoftFail extends DeviceLocationOutcome {
  DeviceLocationSoftFail(this.reason);

  final DeviceLocationFailure reason;
}

/// One-shot device GPS/Wi-Fi/cell fix for the Nearby tab ("use my location").
///
/// Contract, matching the project privacy rules: opt-in only (the caller
/// decides when to ask), coordinates are returned once and never persisted,
/// logged, or transmitted anywhere by this class.
///
/// Wrapped behind an interface so tests can fake positions without platform
/// channels, and so web (browser geolocation) can slot in later.
abstract class DeviceLocationSource {
  Future<DeviceLocationOutcome> getCurrent();
}

/// Default implementation backed by `package:geolocator`.
class GeolocatorDeviceLocation implements DeviceLocationSource {
  GeolocatorDeviceLocation({this.requestTimeout = const Duration(seconds: 12)});

  /// Long enough for a cold Wi-Fi/cell fix on an older Android, short enough
  /// that a stalled radio cannot hang the Nearby tab.
  final Duration requestTimeout;

  @override
  Future<DeviceLocationOutcome> getCurrent() async {
    // Service check first: asking for permission while the radio is off
    // produces a confusing double prompt on some Android skins.
    if (!await Geolocator.isLocationServiceEnabled()) {
      return DeviceLocationSoftFail(DeviceLocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return DeviceLocationSoftFail(DeviceLocationFailure.permissionDenied);
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return DeviceLocationSoftFail(DeviceLocationFailure.permissionDenied);
      }
    }

    try {
      // One fix, low power, coarse accuracy is plenty for a ~4 km search.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      ).timeout(requestTimeout);
      return DeviceLocationOk(
        GeoPoint(lat: position.latitude, lng: position.longitude),
      );
    } on TimeoutException {
      return DeviceLocationSoftFail(DeviceLocationFailure.unavailable);
    } catch (_) {
      return DeviceLocationSoftFail(DeviceLocationFailure.unavailable);
    }
  }
}
