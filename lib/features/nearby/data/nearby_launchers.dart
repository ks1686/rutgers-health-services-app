import '../../../links/phone_links.dart';

/// External-link helpers for live Nearby cards.
String nearbyDigitsOnly(String phone) => phoneDigitsOnly(phone);

Uri nearbyTelUri(String phone) => phoneTelUri(phone);

Uri nearbySmsUri(String phone) => phoneSmsUri(phone);

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
