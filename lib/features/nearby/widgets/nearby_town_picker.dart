import 'package:flutter/material.dart';

import '../../../theme/cwc_theme.dart';
import '../data/nj_places.dart';

/// North, Central, or South, then a town. Returns null if dismissed.
Future<NearbyPlacePreference?> showNearbyTownPicker(
  BuildContext context, {
  required NearbyPlacePreference current,
}) {
  return showModalBottomSheet<NearbyPlacePreference>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TownPickerSheet(current: current),
  );
}

class _TownPickerSheet extends StatefulWidget {
  const _TownPickerSheet({required this.current});

  final NearbyPlacePreference current;

  @override
  State<_TownPickerSheet> createState() => _TownPickerSheetState();
}

class _TownPickerSheetState extends State<_TownPickerSheet> {
  NjRegion? _region;

  @override
  Widget build(BuildContext context) {
    final region = _region;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: region == null
            ? _RegionStep(
                current: widget.current,
                onPick: (value) => setState(() => _region = value),
              )
            : _TownStep(
                region: region,
                onBack: () => setState(() => _region = null),
                onPick: (town) {
                  Navigator.of(
                    context,
                  ).pop(NearbyPlacePreference(region: region, town: town));
                },
              ),
      ),
    );
  }
}

class _RegionStep extends StatelessWidget {
  const _RegionStep({required this.current, required this.onPick});

  final NearbyPlacePreference current;
  final ValueChanged<NjRegion> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text(
          'Choose an area',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Then pick a town in New Jersey. '
          'Saved now: ${current.region.label}, ${current.town}. '
          'You do not have to share your location.',
          style: const TextStyle(
            color: CwcColors.sub,
            fontSize: 18,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        for (final region in NjRegion.values) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: ValueKey('nearby-region-${region.name}'),
              onPressed: () => onPick(region),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                region.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TownStep extends StatelessWidget {
  const _TownStep({
    required this.region,
    required this.onBack,
    required this.onPick,
  });

  final NjRegion region;
  final VoidCallback onBack;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final towns = kNjTowns[region] ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('nearby-town-back'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Areas',
              ),
              Expanded(
                child: Text(
                  'Towns in ${region.label}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final town in towns)
                ListTile(
                  key: ValueKey('nearby-town-$town'),
                  title: Text(town, style: const TextStyle(fontSize: 18)),
                  minVerticalPadding: 16,
                  onTap: () => onPick(town),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
