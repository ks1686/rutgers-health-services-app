import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import '../../../theme/cwc_theme.dart';
import '../data/nearby_resource.dart';
import '../data/sources/geo_point.dart';

/// Opt-in overhead map for live Nearby (FIND-4).
///
/// Google Maps when [preferGoogleMaps] is true and not on web; otherwise
/// OpenStreetMap-style tiles via `flutter_map` (study default / soft-fail).
class NearbyMapView extends StatelessWidget {
  const NearbyMapView({
    super.key,
    required this.resources,
    required this.preferGoogleMaps,
    this.origin,
    this.selectedId,
    this.onMarkerTap,
    this.height = 300,
  });

  final List<NearbyResource> resources;
  final GeoPoint? origin;
  final String? selectedId;
  final ValueChanged<String>? onMarkerTap;

  /// From [NearbyConfig.preferGoogleMaps]. Ignored on web (always OSM).
  final bool preferGoogleMaps;

  final double height;

  bool get _useGoogle => preferGoogleMaps && !kIsWeb;

  LatLng get _center {
    final o = origin;
    if (o != null) return LatLng(o.lat, o.lng);
    if (resources.isNotEmpty) {
      return LatLng(resources.first.lat, resources.first.lng);
    }
    return const LatLng(40.4862, -74.4518);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: CwcColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _useGoogle
                  ? _GoogleNearbyMap(
                      center: _center,
                      resources: resources,
                      origin: origin,
                      selectedId: selectedId,
                      onMarkerTap: onMarkerTap,
                    )
                  : _OsmNearbyMap(
                      center: _center,
                      resources: resources,
                      origin: origin,
                      selectedId: selectedId,
                      onMarkerTap: onMarkerTap,
                    ),
            ),
          ),
        ),
        if (!_useGoogle) ...[
          const SizedBox(height: 4),
          const Text(
            'Map data © OpenStreetMap',
            style: TextStyle(color: CwcColors.sub, fontSize: 14),
          ),
        ],
      ],
    );
  }
}

class _OsmNearbyMap extends StatelessWidget {
  const _OsmNearbyMap({
    required this.center,
    required this.resources,
    required this.origin,
    required this.selectedId,
    required this.onMarkerTap,
  });

  final LatLng center;
  final List<NearbyResource> resources;
  final GeoPoint? origin;
  final String? selectedId;
  final ValueChanged<String>? onMarkerTap;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (origin != null)
        Marker(
          point: LatLng(origin!.lat, origin!.lng),
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 28,
            semanticLabel: 'Your location',
          ),
        ),
      for (final resource in resources)
        Marker(
          key: ValueKey('osm-pin-${resource.id}'),
          point: LatLng(resource.lat, resource.lng),
          width: 40,
          height: 40,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: onMarkerTap == null ? null : () => onMarkerTap!(resource.id),
            child: Icon(
              Icons.location_on,
              color: resource.id == selectedId
                  ? CwcColors.primary
                  : CwcColors.ink,
              size: 40,
              semanticLabel: resource.name,
            ),
          ),
        ),
    ];

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'org.rutgers.cwc.cwc_health_app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

class _GoogleNearbyMap extends StatelessWidget {
  const _GoogleNearbyMap({
    required this.center,
    required this.resources,
    required this.origin,
    required this.selectedId,
    required this.onMarkerTap,
  });

  final LatLng center;
  final List<NearbyResource> resources;
  final GeoPoint? origin;
  final String? selectedId;
  final ValueChanged<String>? onMarkerTap;

  Set<gmaps.Marker> get _markers {
    final out = <gmaps.Marker>{};
    final originPoint = origin;
    if (originPoint != null) {
      out.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('you'),
          position: gmaps.LatLng(originPoint.lat, originPoint.lng),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
          infoWindow: const gmaps.InfoWindow(title: 'You'),
        ),
      );
    }
    for (final resource in resources) {
      final selected = resource.id == selectedId;
      out.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(resource.id),
          position: gmaps.LatLng(resource.lat, resource.lng),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            selected
                ? gmaps.BitmapDescriptor.hueRose
                : gmaps.BitmapDescriptor.hueRed,
          ),
          infoWindow: gmaps.InfoWindow(title: resource.name),
          onTap: onMarkerTap == null ? null : () => onMarkerTap!(resource.id),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(center.latitude, center.longitude),
        zoom: 14,
      ),
      markers: _markers,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }
}
