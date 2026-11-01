import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/link_launcher.dart';
import '../more/using_this_app_page.dart';

/// Care warning shown at the start of every process (#19).
///
/// Acknowledging it lasts until the app is fully closed. It is not stored.
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({
    super.key,
    required this.onAcknowledged,
    this.launcher,
  });

  final VoidCallback onAcknowledged;
  final LinkLauncher? launcher;

  Future<void> _call(BuildContext context, String number) async {
    final open = launcher ?? _launchExternal;
    var opened = false;
    try {
      opened = await open(Uri(scheme: 'tel', path: number));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the phone dialer. Dial $number.'),
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
      // The words scroll. The buttons stay pinned below them so "I understand"
      // and the crisis lines can always be reached, at any text size (C1).
      body: SafeArea(
        bottom: false,
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Before you continue',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                const Text(
                  'If this is an emergency, call 911. Do not spend time '
                  'looking through this app for a hospital or other services.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This app is not a substitute for professional medical '
                  'advice.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Talk with your healthcare providers about your own health.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const UsingThisAppPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Read the full agreement in More',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _DisclaimerActions(
        onCall911: () => _call(context, '911'),
        onCall988: () => _call(context, '988'),
        onAcknowledged: onAcknowledged,
      ),
    );
  }
}

/// Pinned footer. Its labels grow with the text size up to [maxTextScale],
/// so all three buttons fit on a small phone even at the largest setting.
class _DisclaimerActions extends StatelessWidget {
  const _DisclaimerActions({
    required this.onCall911,
    required this.onCall988,
    required this.onAcknowledged,
  });

  static const maxTextScale = 1.5;

  final VoidCallback onCall911;
  final VoidCallback onCall988;
  final VoidCallback onAcknowledged;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: const Border(top: BorderSide(color: CwcColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: onCall911,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CwcColors.neutralEmphasis,
                    side: const BorderSide(
                      color: CwcColors.neutralEmphasis,
                      width: 1.5,
                    ),
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text(
                    'Call 911',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onCall988,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CwcColors.primary,
                    side: const BorderSide(
                      color: CwcColors.primary,
                      width: 1.5,
                    ),
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text(
                    'Call 988',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
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
      ),
    );
  }
}
