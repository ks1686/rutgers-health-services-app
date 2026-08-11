import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/demo_snackbar.dart';
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
                onTap: () => _open(
                  context,
                  'How to Use This App',
                  'Tutorials and short videos will live here. '
                      'This demo only shows navigation.',
                ),
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
                icon: Icons.handshake_outlined,
                title: 'Helper Mode',
                onTap: () => _open(
                  context,
                  'Helper Mode',
                  'Peer support specialists will use sample data here '
                      'for training — not wired in this navigation demo.',
                ),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => _open(
                  context,
                  'Settings',
                  'Text size, optional PIN, and town preference will go here.',
                ),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.privacy_tip_outlined,
                title: 'How This App Protects You',
                onTap: () => _open(
                  context,
                  'How This App Protects You',
                  'Plain-language privacy copy will be co-written with the '
                      'advisory committee. In the real app, your health info '
                      'stays on your phone.',
                ),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.delete_outline,
                title: 'Erase My Information',
                titleColor: CwcColors.neutralEmphasis,
                onTap: () =>
                    showDemoOnlySnackBar(context, 'Erase my information'),
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
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: titleColor ?? CwcColors.ink,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
