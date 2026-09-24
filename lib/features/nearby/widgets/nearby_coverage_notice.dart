import 'package:flutter/material.dart';

import '../../../theme/cwc_theme.dart';

/// Plain Nearby warning (#31). We do not look up insurance or walk-ins.
const kNearbyCoverageWarning =
    'We cannot say whether a place takes someone’s insurance or walk-ins.';

class NearbyCoverageNotice extends StatelessWidget {
  const NearbyCoverageNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      kNearbyCoverageWarning,
      style: TextStyle(color: CwcColors.ink, fontSize: 18, height: 1.35),
    );
  }
}
