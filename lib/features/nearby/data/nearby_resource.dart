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
    required this.source,
    required this.fetchedAt,
    this.phone,
    this.openingHoursRaw,
  });

  final String id;
  final String name;

  /// Display label matching Nearby filter chips (e.g. `Pharmacy`).
  final String category;
  final String address;
  final String? phone;
  final double lat;
  final double lng;

  /// Raw OSM `opening_hours` tag, or null when unknown.
  final String? openingHoursRaw;

  /// One of: `google`, `osm`, `cache`.
  final String source;
  final DateTime fetchedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'address': address,
    'phone': phone,
    'lat': lat,
    'lng': lng,
    'openingHoursRaw': openingHoursRaw,
    'source': source,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
  };

  static NearbyResource fromJson(Map<String, dynamic> json) {
    return NearbyResource(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      openingHoursRaw: json['openingHoursRaw'] as String?,
      source: json['source'] as String,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String).toUtc(),
    );
  }
}
