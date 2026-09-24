import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/demo_banner.dart';
import '../how_to/how_to_screen.dart';
import '../my_health/health_scope.dart';
import '../settings/settings_screen.dart';
import '../wellness/wellness_goals_screen.dart';
import 'about_this_app_page.dart';
import 'helper_privacy_screen.dart';
import 'placeholder_page.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _open(BuildContext context, String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceholderPage(title: title, body: body),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _erase(BuildContext context) async {
    final health = HealthScope.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase my information?'),
        content: const Text(
          'This deletes appointments, medications, providers, wallet details, '
          'and your My Health PIN from this phone. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CwcColors.neutralEmphasis,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (health == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach My Health storage.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await health.eraseAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your My Health information was erased from this phone.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const DemoBanner(),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _MoreTile(
                icon: Icons.school_outlined,
                title: 'How to Use This App',
                onTap: () => _push(context, const HowToScreen()),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.people_outline,
                title: 'Ask a Peer',
                onTap: () => _open(
                  context,
                  'Ask a Peer',
                  'Your Wellness Center contact would appear here '
                      '(call and text). Sample only in this build.',
                ),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.flag_outlined,
                title: 'Wellness goals',
                onTap: () => _push(context, const WellnessGoalsScreen()),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.handshake_outlined,
                title: 'Helper Mode',
                onTap: () => _push(context, const HelperPrivacyScreen()),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.info_outline,
                title: 'About this app',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutThisAppPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => _push(context, const SettingsScreen()),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.privacy_tip_outlined,
                title: 'How This App Protects You',
                onTap: () => _open(
                  context,
                  'How This App Protects You',
                  'Your appointments, medications, and providers stay on this '
                      'phone only — not in a cloud account we can see. '
                      'They are stored with the phone’s built-in secure storage '
                      '(Android Keystore / iOS Keychain). '
                      'Optional PIN locks My Health on screen. Help Now is never '
                      'locked. More privacy wording will be co-written with the '
                      'advisory committee.',
                ),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.delete_outline,
                title: 'Erase My Information',
                titleColor: CwcColors.neutralEmphasis,
                onTap: () => _erase(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 16,
      leading: Icon(icon, color: titleColor ?? CwcColors.ink),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: titleColor ?? CwcColors.ink,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
