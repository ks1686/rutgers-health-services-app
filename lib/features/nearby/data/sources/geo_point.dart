/// Geographic center and optional bounding box from geocoding.
class GeoPoint {
  const GeoPoint({
    required this.lat,
    required this.lng,
    this.bboxSouth,
    this.bboxNorth,
    this.bboxWest,
    this.bboxEast,
  });

  final double lat;
  final double lng;
  final double? bboxSouth;
  final double? bboxNorth;
  final double? bboxWest;
  final double? bboxEast;

  /// True when all four bbox edges are present.
  bool get hasBbox =>
      bboxSouth != null &&
      bboxNorth != null &&
      bboxWest != null &&
      bboxEast != null;

  Map<String, Object?> toJson() => {
    'lat': lat,
    'lng': lng,
    'bboxSouth': bboxSouth,
    'bboxNorth': bboxNorth,
    'bboxWest': bboxWest,
    'bboxEast': bboxEast,
  };

  static GeoPoint fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      bboxSouth: (json['bboxSouth'] as num?)?.toDouble(),
      bboxNorth: (json['bboxNorth'] as num?)?.toDouble(),
      bboxWest: (json['bboxWest'] as num?)?.toDouble(),
      bboxEast: (json['bboxEast'] as num?)?.toDouble(),
    );
  }
}
