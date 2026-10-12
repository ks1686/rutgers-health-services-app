/// Compile-time configuration for the Nearby locator.
///
/// Nearby is always live. There is no compile flag and no static fallback
/// list: the fake New Brunswick directory that used to back `LIVE_NEARBY=false`
/// has been removed, so a build can never ship placeholder places. When the
/// lookup fails the screen says the list is unavailable, which is the honest
/// answer for a member.
///
/// Keys must come from `--dart-define`, never from committed files.
class NearbyConfig {
  const NearbyConfig({
    this.googlePlacesApiKey = '',
    this.googleMapsApiKey = '',
  });

  /// Optional Google Places attempt. The study build has no billing, so this
  /// soft-fails silently to OpenStreetMap, which is the supported path.
  final String googlePlacesApiKey;

  /// Empty (study default) → OSM map soft-fail. Never commit a real key.
  final String googleMapsApiKey;

  /// Google Maps SDK path when a key is present and this is not Flutter web.
  bool get preferGoogleMaps => googleMapsApiKey.isNotEmpty;

  static NearbyConfig fromEnvironment() {
    return const NearbyConfig(
      googlePlacesApiKey: String.fromEnvironment(
        'GOOGLE_PLACES_API_KEY',
        defaultValue: '',
      ),
      googleMapsApiKey: String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: '',
      ),
    );
  }
}
