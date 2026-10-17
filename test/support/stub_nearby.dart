import 'package:cwc_health_app/features/nearby/data/nearby_config.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_fetch_result.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_query.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_repository.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_resource.dart';
import 'package:cwc_health_app/features/nearby/data/sources/google_places_source.dart';
import 'package:cwc_health_app/features/nearby/data/sources/nominatim_geocode.dart';
import 'package:cwc_health_app/features/nearby/data/sources/osm_overpass_source.dart';
import 'package:http/http.dart' as http;

/// Offline Nearby for widget tests.
///
/// Nearby is always live, so a widget test that taps the Nearby tab would
/// otherwise reach Nominatim and Overpass. This stub returns a fixed result
/// and never touches the network.
class StubNearbyRepository extends NearbyRepository {
  StubNearbyRepository({required this.result, DateTime? fetchedAt})
    : super(
        config: const NearbyConfig(),
        geocoder: NominatimGeocode(_refuse()),
        googlePlaces: GooglePlacesSource(_refuse(), apiKey: ''),
        overpass: OsmOverpassSource(_refuse()),
        clock: () => fetchedAt ?? DateTime.utc(2026, 10, 12, 12),
      );

  final NearbyFetchResult result;

  static int calls = 0;

  @override
  Future<NearbyFetchResult> fetch(NearbyQuery query) async {
    calls++;
    return result;
  }

  @override
  Future<NearbyFetchResult> fetchNearDevice(NearbyQuery query) async {
    calls++;
    return result;
  }
}

/// Any real request would throw, so an accidental network call in a widget
/// test fails loudly instead of silently reaching OpenStreetMap.
http.Client _refuse() => _RefusingClient();

/// A convenience factory for a two-row stub result.
NearbyFetchResult stubNearbyResult({
  List<NearbyResource> resources = const [],
  String? message,
}) {
  return NearbyFetchResult(
    resources: resources,
    status: resources.isEmpty
        ? NearbySourceStatus.unavailable
        : NearbySourceStatus.osm,
    fetchedAt: DateTime.utc(2026, 10, 12, 12),
    message: message,
  );
}

NearbyResource stubResource({
  required String name,
  NearbyCategory category = NearbyCategory.pharmacy,
  String phone = '(555) 010-0000',
}) {
  return NearbyResource(
    id: 'stub-$name',
    name: name,
    category: category,
    address: '1 College Ave, New Brunswick, NJ',
    lat: 40.4862,
    lng: -74.4518,
    openingHoursRaw: null,
    source: 'osm',
    fetchedAt: DateTime.utc(2026, 10, 12, 12),
    phone: phone,
  );
}

class _RefusingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw StateError(
        'widget tests must not reach the network: ${request.url}',
      );
}
