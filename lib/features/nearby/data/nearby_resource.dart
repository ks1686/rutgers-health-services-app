/// Which backend produced (or last served) a live Nearby payload.
enum NearbySourceStatus { google, osm, cache, unavailable }

/// Live-directory categories for the study spike (subset of demo chips).
enum NearbyCategory {
  pharmacy,
  clinic,
  urgentCare,
  hospital;

  /// Labels must match demo filter chips where they overlap.
  String get label => switch (this) {
    NearbyCategory.pharmacy => 'Pharmacy',
    NearbyCategory.clinic => 'Clinic',
    NearbyCategory.urgentCare => 'Urgent care',
    NearbyCategory.hospital => 'Hospital',
  };

  /// Reads a [label] back, as cached JSON stores it. Null when unknown.
  static NearbyCategory? fromLabel(String? label) {
    for (final category in values) {
      if (category.label == label) return category;
    }
    return null;
  }
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

  /// Chips filter on this. Its [NearbyCategory.label] is display only.
  final NearbyCategory category;
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
    'category': category.label,
    'address': address,
    'phone': phone,
    'lat': lat,
    'lng': lng,
    'openingHoursRaw': openingHoursRaw,
    'source': source,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
  };

  /// Throws [FormatException] for an unknown category, so a stale cache
  /// entry is dropped and fetched again.
  static NearbyResource fromJson(Map<String, dynamic> json) {
    final label = json['category'] as String?;
    final category = NearbyCategory.fromLabel(label);
    if (category == null) {
      throw FormatException('Unknown Nearby category', label);
    }
    return NearbyResource(
      id: json['id'] as String,
      name: json['name'] as String,
      category: category,
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
