import 'package:flutter/material.dart';

import '../../../theme/cwc_theme.dart';
import '../data/opening_hours.dart';

class NearbyHoursControl extends StatefulWidget {
  const NearbyHoursControl({super.key, required this.view});

  final OpeningHoursView view;

  @override
  State<NearbyHoursControl> createState() => _NearbyHoursControlState();
}

class _NearbyHoursControlState extends State<NearbyHoursControl> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    if (view.kind == OpeningHoursKind.unknown) {
      return const Text(
        'Hours not listed',
        style: TextStyle(color: CwcColors.sub, fontSize: 18, height: 1.3),
      );
    }

    final summary = view.kind == OpeningHoursKind.openNow
        ? 'Open now'
        : 'Closed';
    final action = _expanded ? 'hide hours' : 'show hours';
    final lines = view.weekdayLines!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: '$summary, $action',
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Text(
                      summary,
                      style: const TextStyle(
                        color: CwcColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: CwcColors.sub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(
                  color: CwcColors.sub,
                  fontSize: 18,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
