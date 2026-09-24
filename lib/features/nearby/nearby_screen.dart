import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/demo_resources.dart';
import '../../theme/cwc_theme.dart';
import '../settings/app_preferences.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/demo_snackbar.dart';
import 'data/nearby_config.dart';
import 'data/nearby_distance.dart';
import 'data/nearby_errors.dart';
import 'data/nearby_fetch_result.dart';
import 'data/nearby_launchers.dart';
import 'data/nearby_place_preference.dart';
import 'data/nearby_query.dart';
import 'data/nearby_repository.dart';
import 'data/nearby_resource.dart';
import 'data/nj_places.dart';
import 'data/prefs_nearby_cache.dart';
import 'data/opening_hours.dart';
import 'widgets/nearby_coverage_notice.dart';
import 'widgets/nearby_hours_control.dart';
import 'widgets/nearby_live_disclaimer.dart';
import 'widgets/nearby_map_view.dart';
import 'widgets/nearby_town_picker.dart';

typedef NearbyLinkLauncher = Future<bool> Function(Uri uri);

/// Nearby tab. Static demo by default; live locator behind `LIVE_NEARBY`.
class NearbyScreen extends StatelessWidget {
  const NearbyScreen({
    super.key,
    this.config,
    this.repository,
    this.launcher,
    this.clock,
    this.placePreference,
  });

  final NearbyConfig? config;
  final NearbyRepository? repository;
  final NearbyLinkLauncher? launcher;
  final DateTime Function()? clock;
  final NearbyPlacePreferenceStore? placePreference;

  @override
  Widget build(BuildContext context) {
    final resolved = config ?? NearbyConfig.fromEnvironment();
    if (!resolved.liveNearby) {
      return _NearbyDemoView(placePreference: placePreference);
    }
    return _NearbyLiveView(
      config: resolved,
      repository: repository,
      launcher: launcher,
      clock: clock,
      placePreference: placePreference,
    );
  }
}

class _NearbyDemoView extends StatefulWidget {
  const _NearbyDemoView({this.placePreference});

  final NearbyPlacePreferenceStore? placePreference;

  @override
  State<_NearbyDemoView> createState() => _NearbyDemoViewState();
}

Future<void> _publishRememberedTown(
  BuildContext context,
  NearbyPlacePreference picked,
) async {
  final prefs = AppPreferencesScope.maybeOf(context);
  if (prefs == null || prefs.rememberedTown == picked.town) return;
  await prefs.setRememberedTown(picked.town);
}

class _NearbyDemoViewState extends State<_NearbyDemoView> {
  String _category = 'All';
  bool _showMapPlaceholder = false;
  NearbyPlacePreference _place = NearbyPlacePreference.fallback;
  NearbyPlacePreferenceStore? _placeStore;

  List<DemoResource> get _filtered {
    if (_place.town != demoTown) return const [];
    if (_category == 'All') return demoResources;
    return demoResources.where((r) => r.category == _category).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final remembered = AppPreferencesScope.maybeOf(context)?.rememberedTown;
    if (remembered == null) return;
    final town = nearbyTownFromPreference(remembered);
    if (town == _place.town) return;
    final listed = regionForTown(town);
    setState(() {
      _place = NearbyPlacePreference(
        region: listed ?? _place.region,
        town: town,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPlace();
  }

  Future<void> _loadPlace() async {
    final store = await nearbyPlacePreferenceStore(
      injected: widget.placePreference,
    );
    final place = await store.read();
    if (!mounted) return;
    setState(() {
      _placeStore = store;
      _place = place;
    });
  }

  Future<void> _pickTown() async {
    final store = _placeStore;
    if (store == null) return;
    final picked = await showNearbyTownPicker(context, current: _place);
    if (picked == null || !mounted) return;
    await store.save(picked);
    if (!mounted) return;
    setState(() => _place = picked);
    await _publishRememberedTown(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const DemoBanner(),
        const SizedBox(height: 12),
        const NearbyCoverageNotice(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              key: const ValueKey('nearby-town-chip'),
              avatar: const Icon(Icons.location_city, size: 18),
              label: Text('${_place.town} ▾'),
              onPressed: _placeStore == null ? null : _pickTown,
            ),
            TextButton(
              onPressed: () => showDemoOnlySnackBar(context, 'use my location'),
              child: const Text('Use my location?'),
            ),
          ],
        ),
        if (_place.town != demoTown) ...[
          const SizedBox(height: 12),
          const Text(
            'This sample list is only for New Brunswick. '
            'Your town is saved on this phone.',
            style: TextStyle(color: CwcColors.sub, fontSize: 18, height: 1.35),
          ),
        ],
        const SizedBox(height: 12),
        _CategoryChips(
          categories: demoCategories,
          selected: _category,
          onSelected: (category) => setState(() => _category = category),
        ),
        const SizedBox(height: 8),
        _MapToggle(
          value: _showMapPlaceholder,
          subtitle: 'Map is a placeholder in this demo',
          onChanged: (value) => setState(() => _showMapPlaceholder = value),
        ),
        if (_showMapPlaceholder) const _MapPlaceholder(),
        for (final resource in _filtered) ...[
          _PlaceCard(
            name: resource.name,
            hours: Text(
              resource.status,
              style: const TextStyle(color: CwcColors.sub, fontSize: 18),
            ),
            description: resource.description,
            badges: [
              resource.walkTime,
              if (resource.transitHint != null) resource.transitHint!,
            ],
            address: resource.address,
            actions: [
              OutlinedButton(
                onPressed: () => showDemoOnlySnackBar(context, 'Call'),
                child: const Text('Call'),
              ),
              OutlinedButton(
                onPressed: () => showDemoOnlySnackBar(context, 'Text'),
                child: const Text('Text'),
              ),
              OutlinedButton(
                onPressed: () => showDemoOnlySnackBar(context, 'Directions'),
                child: const Text('Directions'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _NearbyLiveView extends StatefulWidget {
  const _NearbyLiveView({
    required this.config,
    this.repository,
    this.launcher,
    this.clock,
    this.placePreference,
  });

  final NearbyConfig config;
  final NearbyRepository? repository;
  final NearbyLinkLauncher? launcher;
  final DateTime Function()? clock;
  final NearbyPlacePreferenceStore? placePreference;

  @override
  State<_NearbyLiveView> createState() => _NearbyLiveViewState();
}

class _NearbyLiveViewState extends State<_NearbyLiveView> {
  NearbyQuery _query = const NearbyQuery();
  NearbyPlacePreference _place = NearbyPlacePreference.fallback;
  NearbyPlacePreferenceStore? _placeStore;

  /// Derived from the source enum so a renamed category cannot silently stop
  /// matching the chip that filters it.
  static final _categories = [
    'All',
    ...NearbyCategory.values.map((category) => category.label),
  ];

  http.Client? _ownedClient;
  late final NearbyRepository _repository;
  late Future<NearbyFetchResult> _pending;

  String _category = 'All';
  bool _reloadQueued = false;

  /// True once [_boot] has finished wiring the default stack. Build and
  /// user actions check this instead of touching the late field directly.
  bool _repositoryReady = false;

  /// Whether the tab currently shows a device-location lookup (vs the town).
  bool _deviceMode = false;

  /// Optimistic flag while a device lookup is in flight (loading copy).
  bool _devicePending = false;

  /// Plain-language reason shown when a device attempt had to fall back.
  String? _infoLine;

  /// Live FIND-4 map toggle (tiles load only when on).
  bool _showMap = false;

  /// Pin ↔ card highlight (resource id).
  String? _selectedResourceId;

  final Map<String, GlobalKey> _cardKeys = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final remembered = AppPreferencesScope.maybeOf(context)?.rememberedTown;
    if (remembered == null) return;
    final town = nearbyTownFromPreference(remembered);
    if (town == _query.town && town == _place.town) return;
    final listed = regionForTown(town);
    _place = NearbyPlacePreference(region: listed ?? _place.region, town: town);
    _query = NearbyQuery(town: town);
    if (_repositoryReady && !_deviceMode && !_reloadQueued) {
      _reload();
    }
  }

  @override
  void initState() {
    super.initState();
    _pending = _start();
  }

  /// Remembered town is the lookup. Device location stays an optional shortcut.
  Future<NearbyFetchResult> _start() async {
    await _loadPlace();
    final injected = widget.repository;
    if (injected != null) {
      _repository = injected;
      _repositoryReady = true;
      return _lookupTown();
    }
    return _boot();
  }

  Future<void> _loadPlace() async {
    final store = await nearbyPlacePreferenceStore(
      injected: widget.placePreference,
    );
    final place = await store.read();
    if (!mounted) return;
    setState(() {
      _placeStore = store;
      _place = place;
      _query = NearbyQuery(town: place.town);
    });
  }

  /// One-shot device fix is available when a source is wired.
  /// Declining / failing never blocks — [fetchNearDevice] falls back to town.
  bool get _canUseDeviceLocation =>
      _repositoryReady && (_repository.deviceLocation != null);

  @override
  void dispose() {
    _ownedClient?.close();
    super.dispose();
  }

  Future<NearbyFetchResult> _boot() async {
    final prefs = await SharedPreferences.getInstance();
    final client = http.Client();
    _ownedClient = client;
    _repository = NearbyRepository.fromClient(
      client,
      config: widget.config,
      cache: PrefsNearbyCache(prefs),
    );
    _repositoryReady = true;
    return _lookupTown();
  }

  Future<NearbyFetchResult> _lookupTown() {
    _devicePending = false;
    return _repository.fetch(_query);
  }

  Future<void> _pickTown() async {
    final store = _placeStore;
    if (store == null || !_repositoryReady || _reloadQueued) return;
    final picked = await showNearbyTownPicker(context, current: _place);
    if (picked == null || !mounted) return;
    await store.save(picked);
    if (!mounted || _reloadQueued) return;
    _reloadQueued = true;
    setState(() {
      _place = picked;
      _query = NearbyQuery(town: picked.town);
      _deviceMode = false;
      _devicePending = false;
      _infoLine = null;
      _selectedResourceId = null;
      _pending = _repository.fetch(_query).whenComplete(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _reloadQueued = false);
        });
      });
    });
    await _publishRememberedTown(context, picked);
  }

  void _reload() {
    if (_reloadQueued || !_repositoryReady) return;
    if (_deviceMode && _canUseDeviceLocation) {
      _useMyLocation();
      return;
    }
    _reloadQueued = true;
    setState(() {
      _deviceMode = false;
      _devicePending = false;
      _infoLine = null;
      _pending = _repository.fetch(_query).whenComplete(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _reloadQueued = false);
        });
      });
    });
  }

  /// One-shot device location. Coordinates stay in memory for this lookup only.
  void _useMyLocation() {
    if (_reloadQueued || !_canUseDeviceLocation) return;
    _reloadQueued = true;
    setState(() {
      _devicePending = true;
      _pending = _trackDeviceLookup(_repository.fetchNearDevice(_query));
    });
  }

  Future<NearbyFetchResult> _trackDeviceLookup(
    Future<NearbyFetchResult> pending,
  ) {
    return pending
        .then((result) {
          final usedDevice = result.origin != null;
          if (!mounted) return result;
          setState(() {
            _deviceMode = usedDevice;
            _devicePending = false;
            // On success the empty-state copy carries its own message; only a
            // fallback keeps a reason line visible.
            _infoLine = usedDevice ? null : result.message;
          });
          return result;
        })
        .whenComplete(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _reloadQueued = false);
          });
        });
  }

  void _onMarkerTap(String resourceId) {
    setState(() => _selectedResourceId = resourceId);
    final key = _cardKeys[resourceId];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 280),
        alignment: 0.1,
        curve: Curves.easeOut,
      );
    }
  }

  GlobalKey _keyFor(String id) => _cardKeys.putIfAbsent(id, GlobalKey.new);

  Future<void> _open(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final launcher = widget.launcher ?? _launchExternal;
    final opened = await launcher(uri);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open that on this phone.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NearbyFetchResult>(
      future: _pending,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading();
        }
        final result = snapshot.data;
        if (result == null) {
          return _buildProblem(
            kNearbyMemberLoadFailed,
            suggestConnection: true,
          );
        }
        // An empty *town* lookup is a problem view (plain message + retry).
        // An empty *device* lookup still gets the results chrome — origin
        // chip, categories, and its own gentle near-you sentence.
        if (result.resources.isEmpty && result.origin == null) {
          return _buildProblem(
            result.message ?? kNearbyMemberLoadFailed,
            suggestConnection: result.status == NearbySourceStatus.unavailable,
          );
        }
        return _buildResults(result);
      },
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      children: [
        const Center(
          child: CircularProgressIndicator(color: CwcColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          _devicePending
              ? 'Finding your location…'
              : 'Finding places near ${_query.town}…',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CwcColors.sub),
        ),
      ],
    );
  }

  Widget _placeControls() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ActionChip(
          key: const ValueKey('nearby-town-chip'),
          avatar: Icon(
            _deviceMode ? Icons.my_location : Icons.location_city,
            size: 18,
          ),
          label: Text(_deviceMode ? 'Using your location' : '${_query.town} ▾'),
          onPressed: _reloadQueued ? null : _pickTown,
        ),
        if (_canUseDeviceLocation && !_deviceMode)
          TextButton.icon(
            key: const ValueKey('nearby-use-my-location'),
            onPressed: _reloadQueued ? null : _useMyLocation,
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Use my location'),
          ),
      ],
    );
  }

  Widget _buildProblem(String message, {required bool suggestConnection}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _placeControls(),
        const SizedBox(height: 12),
        const NearbyCoverageNotice(),
        const SizedBox(height: 24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CwcColors.ink, height: 1.4),
        ),
        if (suggestConnection) ...[
          const SizedBox(height: 8),
          const Text(
            'Check your connection, then try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CwcColors.sub, fontSize: 18, height: 1.4),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: FilledButton(
            onPressed: _reloadQueued ? null : _reload,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(NearbyFetchResult result) {
    final rows = _category == 'All'
        ? result.resources
        : result.resources.where((r) => r.category == _category).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        NearbyLiveDisclaimer(
          fetchedAt: result.fetchedAt,
          fromSavedCopy: result.status == NearbySourceStatus.cache,
        ),
        const SizedBox(height: 12),
        const NearbyCoverageNotice(),
        const SizedBox(height: 16),
        _placeControls(),
        if (_infoLine != null) ...[
          const SizedBox(height: 8),
          Text(
            _infoLine!,
            style: const TextStyle(color: CwcColors.sub, fontSize: 18),
          ),
        ],
        const SizedBox(height: 12),
        _CategoryChips(
          categories: _categories,
          selected: _category,
          onSelected: (category) => setState(() {
            _category = category;
            _selectedResourceId = null;
          }),
        ),
        const SizedBox(height: 8),
        _MapToggle(
          key: const ValueKey('nearby-map-toggle'),
          value: _showMap,
          subtitle: _showMap
              ? 'Showing places from this list'
              : 'Optional map — uses your connection for tiles',
          onChanged: (value) => setState(() => _showMap = value),
        ),
        if (_showMap) ...[
          NearbyMapView(
            key: const ValueKey('nearby-map-view'),
            resources: rows,
            preferGoogleMaps: widget.config.preferGoogleMaps,
            origin: result.origin,
            selectedId: _selectedResourceId,
            onMarkerTap: _onMarkerTap,
          ),
          const SizedBox(height: 12),
        ],
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              _deviceMode
                  ? (result.message ?? kNearbyNoPlacesNearYou)
                  : 'No ${_category.toLowerCase()} places found near '
                        '${_query.town}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CwcColors.sub, height: 1.4),
            ),
          ),
        for (final resource in rows) ...[
          KeyedSubtree(
            key: _keyFor(resource.id),
            child: _PlaceCard(
              name: resource.name,
              selected: resource.id == _selectedResourceId,
              hours: NearbyHoursControl(
                key: ValueKey(resource.id),
                view: parseOpeningHours(
                  resource.openingHoursRaw,
                  (widget.clock ?? DateTime.now)(),
                ),
              ),
              badges: [
                resource.category,
                if (result.origin != null) ...[
                  '~${nearbyWalkMinutes(nearbyDistanceMeters(fromLat: result.origin!.lat, fromLng: result.origin!.lng, toLat: resource.lat, toLng: resource.lng))} min walk',
                ],
              ],
              address: resource.address,
              description: resource.phone == null ? 'Phone not listed' : null,
              actions: _actionsFor(resource),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<Widget> _actionsFor(NearbyResource resource) {
    final phone = resource.phone;
    return [
      if (phone != null) ...[
        OutlinedButton(
          onPressed: () => _open(nearbyTelUri(phone)),
          child: const Text('Call'),
        ),
        OutlinedButton(
          onPressed: () => _open(nearbySmsUri(phone)),
          child: const Text('Text'),
        ),
      ],
      OutlinedButton(
        onPressed: () => _open(
          nearbyDirectionsUri(
            lat: resource.lat,
            lng: resource.lng,
            name: resource.name,
            isWeb: kIsWeb,
          ),
        ),
        child: const Text('Directions'),
      ),
    ];
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapToggle extends StatelessWidget {
  const _MapToggle({
    super.key,
    required this.value,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('See these on a map'),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: CwcColors.sub, fontSize: 14),
      ),
      value: value,
      activeThumbColor: CwcColors.primary,
      onChanged: onChanged,
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CwcColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CwcColors.line),
      ),
      child: const Text(
        'Map view placeholder\n(OpenStreetMap would load here)',
        textAlign: TextAlign.center,
        style: TextStyle(color: CwcColors.sub, height: 1.4),
      ),
    );
  }
}

/// Shared card chrome so demo and live listings stay visually identical.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.name,
    required this.hours,
    required this.badges,
    required this.address,
    required this.actions,
    this.description,
    this.selected = false,
  });

  final String name;
  final Widget hours;
  final List<String> badges;
  final String address;
  final List<Widget> actions;
  final String? description;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 2 : null,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CwcColors.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            hours,
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!),
            ],
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [for (final badge in badges) _Badge(label: badge)],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              address,
              style: const TextStyle(color: CwcColors.sub, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CwcColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
