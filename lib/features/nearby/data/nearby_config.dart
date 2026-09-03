/// Compile-time flags for the Nearby live-data path.
///
/// Defaults keep demos on static data. Keys must come from `--dart-define`,
/// never from committed files.
class NearbyConfig {
  const NearbyConfig({
    required this.liveNearby,
    required this.googlePlacesApiKey,
    this.googleMapsApiKey = '',
  });

  final bool liveNearby;
  final String googlePlacesApiKey;

  /// Empty (study default) → OSM map soft-fail. Never commit a real key.
  final String googleMapsApiKey;

  /// Google Maps SDK path when a key is present and this is not Flutter web.
  bool get preferGoogleMaps => googleMapsApiKey.isNotEmpty;

  static NearbyConfig fromEnvironment() {
    return const NearbyConfig(
      liveNearby: bool.fromEnvironment('LIVE_NEARBY', defaultValue: false),
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
