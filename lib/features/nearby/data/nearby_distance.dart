import 'dart:math' as math;

/// Straight-line meters between two coordinate pairs.
///
/// Equirectangular approximation — accurate well past town-scale distances,
/// which is all this app promises ("about", never exact).
double nearbyDistanceMeters({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _toRadians(toLat - fromLat);
  final dLng = _toRadians(toLng - fromLng);
  final meanLat = _toRadians((fromLat + toLat) / 2);
  final x = dLng * math.cos(meanLat);
  return earthRadiusMeters * math.sqrt(x * x + dLat * dLat);
}

/// Rough walking minutes for [meters] at ~80 m per minute (~4.8 km/h).
///
/// Deliberately naive and rounded: cards say "~10 min walk", not meters.
int nearbyWalkMinutes(double meters) {
  final minutes = (meters / 80).round();
  return minutes < 1 ? 1 : minutes;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
