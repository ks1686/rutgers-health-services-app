import 'package:flutter/material.dart';

import '../theme/cwc_theme.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

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
      child: const Text(
        'Draft for co-design — nothing is final until the community says so.',
        style: TextStyle(
          color: CwcColors.ink,
          fontSize: 18,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
