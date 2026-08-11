/// Compile-time flags for the Nearby live-data path.
///
/// Defaults keep demos on static data. Keys must come from `--dart-define`,
/// never from committed files.
class NearbyConfig {
  const NearbyConfig({
    required this.liveNearby,
    required this.googlePlacesApiKey,
  });

  final bool liveNearby;
  final String googlePlacesApiKey;

  static NearbyConfig fromEnvironment() {
    return const NearbyConfig(
      liveNearby: bool.fromEnvironment('LIVE_NEARBY', defaultValue: false),
      googlePlacesApiKey: String.fromEnvironment(
        'GOOGLE_PLACES_API_KEY',
        defaultValue: '',
      ),
    );
  }
}
