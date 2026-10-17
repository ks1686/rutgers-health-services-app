/// External-link helper for live Nearby cards.
Uri nearbyDirectionsUri({
  required double lat,
  required double lng,
  required String name,
  required bool isWeb,
}) {
  if (isWeb) {
    return Uri.https('www.openstreetmap.org', '/', {
      'mlat': '$lat',
      'mlon': '$lng',
    }).replace(fragment: 'map=16/$lat/$lng');
  }
  final label = Uri.encodeComponent(name);
  return Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
}
