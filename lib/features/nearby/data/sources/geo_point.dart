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
}
