import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/link_launcher.dart';

/// First-launch gate (#19). Shown once; stored on-device after acknowledge.
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({
    super.key,
    required this.onAcknowledged,
    this.launcher,
  });

  final VoidCallback onAcknowledged;
  final LinkLauncher? launcher;

  Future<void> _call911(BuildContext context) async {
    final open = launcher ?? _launchExternal;
    final opened = await open(Uri(scheme: 'tel', path: '911'));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the phone dialer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Before you continue',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              const Text(
                'If this is an emergency, call 911. Do not spend time looking '
                'through this app for a hospital or other services.',
                style: TextStyle(fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'This app is not a substitute for professional medical advice.',
                style: TextStyle(fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Talk with your healthcare providers about your own health.',
                style: TextStyle(fontSize: 18, height: 1.4),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _call911(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CwcColors.neutralEmphasis,
                  side: const BorderSide(
                    color: CwcColors.neutralEmphasis,
                    width: 1.5,
                  ),
                  minimumSize: const Size.fromHeight(64),
                ),
                child: const Text(
                  'Call 911',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onAcknowledged,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text(
                  'I understand',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
