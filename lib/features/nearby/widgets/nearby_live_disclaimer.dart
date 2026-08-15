import 'package:flutter/material.dart';

import '../../../theme/cwc_theme.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Local-time stamp for the "Updated as of" line, e.g. `Aug 12, 2026 at 9:05 PM`.
String formatNearbyTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour < 12 ? 'AM' : 'PM';
  return '${_months[local.month - 1]} ${local.day}, ${local.year} '
      'at $hour:$minute $meridiem';
}

/// Live-mode honesty notice: these listings are not vetted by the study team.
///
/// [fetchedAt] is when the data was actually pulled, so a cached payload keeps
/// its original time rather than claiming to be fresh.
class NearbyLiveDisclaimer extends StatelessWidget {
  const NearbyLiveDisclaimer({
    super.key,
    required this.fetchedAt,
    this.fromSavedCopy = false,
  });

  final DateTime fetchedAt;
  final bool fromSavedCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CwcColors.primaryTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CwcColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'These places come from public maps data. '
            'They are not checked by our team.',
            style: TextStyle(
              color: CwcColors.ink,
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated as of ${formatNearbyTimestamp(fetchedAt)}.',
            style: const TextStyle(
              color: CwcColors.sub,
              fontSize: 18,
              height: 1.35,
            ),
          ),
          if (fromSavedCopy) ...[
            const SizedBox(height: 4),
            const Text(
              'This is a saved copy. We could not reach the internet just now.',
              style: TextStyle(
                color: CwcColors.sub,
                fontSize: 18,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
