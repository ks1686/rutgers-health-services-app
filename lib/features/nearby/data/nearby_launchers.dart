/// External-link helpers for live Nearby cards.
String nearbyDigitsOnly(String phone) =>
    phone.replaceAll(RegExp(r'[^0-9]'), '');

Uri nearbyTelUri(String phone) =>
    Uri(scheme: 'tel', path: nearbyDigitsOnly(phone));

Uri nearbySmsUri(String phone) =>
    Uri(scheme: 'sms', path: nearbyDigitsOnly(phone));

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
