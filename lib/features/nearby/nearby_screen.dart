import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/demo_resources.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/demo_snackbar.dart';
import 'data/nearby_cache.dart';
import 'data/nearby_config.dart';
import 'data/nearby_errors.dart';
import 'data/nearby_fetch_result.dart';
import 'data/nearby_launchers.dart';
import 'data/nearby_query.dart';
import 'data/nearby_repository.dart';
import 'data/nearby_resource.dart';
import 'data/prefs_nearby_cache.dart';
import 'data/opening_hours.dart';
import 'widgets/nearby_hours_control.dart';
import 'widgets/nearby_live_disclaimer.dart';

typedef NearbyLinkLauncher = Future<bool> Function(Uri uri);

/// Nearby tab. Static demo by default; live locator behind `LIVE_NEARBY`.
class NearbyScreen extends StatelessWidget {
  const NearbyScreen({
    super.key,
    this.config,
    this.repository,
    this.launcher,
    this.clock,
  });

  final NearbyConfig? config;
  final NearbyRepository? repository;
  final NearbyLinkLauncher? launcher;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final resolved = config ?? NearbyConfig.fromEnvironment();
    if (!resolved.liveNearby) {
      return const _NearbyDemoView();
    }
    return _NearbyLiveView(
      config: resolved,
      repository: repository,
      launcher: launcher,
      clock: clock,
    );
  }
}

class _NearbyDemoView extends StatefulWidget {
  const _NearbyDemoView();

  @override
  State<_NearbyDemoView> createState() => _NearbyDemoViewState();
}

class _NearbyDemoViewState extends State<_NearbyDemoView> {
  String _category = 'All';
  bool _showMapPlaceholder = false;

  List<DemoResource> get _filtered {
    if (_category == 'All') return demoResources;
    return demoResources.where((r) => r.category == _category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const DemoBanner(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              avatar: const Icon(Icons.location_city, size: 18),
              label: const Text('$demoTown ▾'),
              onPressed: () => showDemoOnlySnackBar(context, 'town picker'),
            ),
            TextButton(
              onPressed: () => showDemoOnlySnackBar(context, 'use my location'),
              child: const Text('Use my location?'),
            ),
          ],
        ),
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
              style: const TextStyle(color: CwcColors.sub, fontSize: 13),
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
  });

  final NearbyConfig config;
  final NearbyRepository? repository;
  final NearbyLinkLauncher? launcher;
  final DateTime Function()? clock;

  @override
  State<_NearbyLiveView> createState() => _NearbyLiveViewState();
}

class _NearbyLiveViewState extends State<_NearbyLiveView> {
  static const _query = NearbyQuery();

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

  @override
  void initState() {
    super.initState();
    final injected = widget.repository;
    if (injected != null) {
      _repository = injected;
      _pending = _repository.fetch(_query);
    } else {
      _pending = _boot();
    }
  }

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
    return _repository.fetch(_query);
  }

  void _reload() {
    if (_reloadQueued) return;
    _reloadQueued = true;
    setState(() {
      _pending = _repository.fetch(_query).whenComplete(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _reloadQueued = false);
        });
      });
    });
  }

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
        if (result.resources.isEmpty) {
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
          'Finding places near ${_query.town}…',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CwcColors.sub),
        ),
      ],
    );
  }

  Widget _buildProblem(String message, {required bool suggestConnection}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      children: [
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
            style: TextStyle(color: CwcColors.sub, fontSize: 13, height: 1.4),
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
        const SizedBox(height: 16),
        Chip(
          avatar: const Icon(Icons.location_city, size: 18),
          label: Text(_query.town),
        ),
        const SizedBox(height: 12),
        _CategoryChips(
          categories: _categories,
          selected: _category,
          onSelected: (category) => setState(() => _category = category),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No ${_category.toLowerCase()} places found near ${_query.town}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CwcColors.sub, height: 1.4),
            ),
          ),
        for (final resource in rows) ...[
          _PlaceCard(
            name: resource.name,
            hours: NearbyHoursControl(
              key: ValueKey(resource.id),
              view: parseOpeningHours(
                resource.openingHoursRaw,
                (widget.clock ?? DateTime.now)(),
              ),
            ),
            badges: [resource.category],
            address: resource.address,
            description: resource.phone == null ? 'Phone not listed' : null,
            actions: _actionsFor(resource),
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
        style: const TextStyle(color: CwcColors.sub, fontSize: 13),
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
  });

  final String name;
  final Widget hours;
  final List<String> badges;
  final String address;
  final List<Widget> actions;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Card(
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
              style: const TextStyle(color: CwcColors.sub, fontSize: 13),
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
