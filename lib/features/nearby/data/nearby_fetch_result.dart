import 'nearby_resource.dart';
import 'sources/geo_point.dart';

/// Outcome of a live Nearby fetch (repository layer).
class NearbyFetchResult {
  const NearbyFetchResult({
    required this.resources,
    required this.status,
    required this.fetchedAt,
    this.message,
    this.origin,
  });

  final List<NearbyResource> resources;
  final NearbySourceStatus status;
  final DateTime fetchedAt;
  final String? message;

  /// Coordinates the search was centered on. Set only for device-location
  /// lookups; town lookups are null. Device results are never written to the
  /// on-device cache, so an origin never reaches storage.
  final GeoPoint? origin;

  Map<String, Object?> toJson() => {
    'resources': [for (final row in resources) row.toJson()],
    'status': status.name,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'message': message,
    'origin': origin?.toJson(),
  };

  static NearbyFetchResult? fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final status = NearbySourceStatus.values.asNameMap()[statusName];
    if (status == null) return null;
    final rows = json['resources'];
    if (rows is! List) return null;
    return NearbyFetchResult(
      resources: [
        for (final row in rows)
          if (row is Map)
            NearbyResource.fromJson(Map<String, dynamic>.from(row)),
      ],
      status: status,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String).toUtc(),
      message: json['message'] as String?,
      origin: json['origin'] is Map
          ? GeoPoint.fromJson(Map<String, dynamic>.from(json['origin'] as Map))
          : null,
    );
  }
}
