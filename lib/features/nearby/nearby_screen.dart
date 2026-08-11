import 'package:flutter/material.dart';

import '../../data/demo_resources.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/demo_snackbar.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in demoCategories) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('See these on a map'),
          subtitle: const Text(
            'Map is a placeholder in this demo',
            style: TextStyle(color: CwcColors.sub, fontSize: 13),
          ),
          value: _showMapPlaceholder,
          activeThumbColor: CwcColors.primary,
          onChanged: (value) => setState(() => _showMapPlaceholder = value),
        ),
        if (_showMapPlaceholder)
          Container(
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
          ),
        for (final resource in _filtered) ...[
          _ResourceCard(resource: resource),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});

  final DemoResource resource;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              resource.status,
              style: const TextStyle(color: CwcColors.sub, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(resource.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge(label: resource.walkTime),
                if (resource.transitHint != null)
                  _Badge(label: resource.transitHint!),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              resource.address,
              style: const TextStyle(color: CwcColors.sub, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
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
