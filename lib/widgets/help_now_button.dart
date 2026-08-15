import 'package:flutter/material.dart';

import '../features/help_now/help_now_screen.dart';

class HelpNowButton extends StatelessWidget {
  const HelpNowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const HelpNowScreen()),
          );
        },
        child: const Text('Help Now'),
      ),
    );
  }
}
