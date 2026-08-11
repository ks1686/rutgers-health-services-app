/// Which backend produced (or last served) a live Nearby payload.
enum NearbySourceStatus { google, osm, cache, unavailable }

/// Live-directory categories for the study spike (subset of demo chips).
enum NearbyCategory {
  pharmacy,
  clinic,
  urgentCare;

  /// Labels must match demo filter chips where they overlap.
  String get label => switch (this) {
    NearbyCategory.pharmacy => 'Pharmacy',
    NearbyCategory.clinic => 'Clinic',
    NearbyCategory.urgentCare => 'Urgent care',
  };
}

/// Normalized place row for list UI (demo or live).
class NearbyResource {
  const NearbyResource({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    required this.source,
    required this.fetchedAt,
    this.phone,
  });

  final String id;
  final String name;

  /// Display label matching Nearby filter chips (e.g. `Pharmacy`).
  final String category;
  final String address;
  final String? phone;
  final double lat;
  final double lng;
  final String status;

  /// One of: `google`, `osm`, `cache`.
  final String source;
  final DateTime fetchedAt;
}
