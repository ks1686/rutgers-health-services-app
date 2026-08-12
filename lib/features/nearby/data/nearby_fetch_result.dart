import 'nearby_resource.dart';

/// Outcome of a live Nearby fetch (repository layer).
class NearbyFetchResult {
  const NearbyFetchResult({
    required this.resources,
    required this.status,
    required this.fetchedAt,
    this.message,
  });

  final List<NearbyResource> resources;
  final NearbySourceStatus status;
  final DateTime fetchedAt;
  final String? message;
}
