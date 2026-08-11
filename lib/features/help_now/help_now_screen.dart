import 'package:flutter/material.dart';

import '../../data/demo_help_now.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/demo_snackbar.dart';

class HelpNowScreen extends StatefulWidget {
  const HelpNowScreen({super.key});

  @override
  State<HelpNowScreen> createState() => _HelpNowScreenState();
}

class _HelpNowScreenState extends State<HelpNowScreen> {
  bool _showEmergencyCard = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Now'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text(
            "You're not alone",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'One tap to reach support. These buttons are demo-only '
            '(they do not place calls or texts yet).',
            style: TextStyle(color: CwcColors.sub, height: 1.4),
          ),
          const SizedBox(height: 20),
          for (final action in demoHelpActions) ...[
            _HelpActionButton(action: action),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show my emergency card here'),
            subtitle: Text(
              _showEmergencyCard
                  ? 'Would show wallet info on this unlocked screen '
                        '(off by default in the real app). Demo toggle only.'
                  : 'Off by default — turning this on would share health '
                        'info on an unlocked screen.',
              style: const TextStyle(color: CwcColors.sub, fontSize: 13),
            ),
            value: _showEmergencyCard,
            activeThumbColor: CwcColors.primary,
            onChanged: (value) => setState(() => _showEmergencyCard = value),
          ),
          if (_showEmergencyCard)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CwcColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CwcColors.line),
              ),
              child: const Text(
                'Emergency card preview (sample)\n'
                'Contact: Alex M. · Medications listed on Wallet Card',
                style: TextStyle(height: 1.4),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Works even without internet',
            textAlign: TextAlign.center,
            style: TextStyle(color: CwcColors.sub, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _HelpActionButton extends StatelessWidget {
  const _HelpActionButton({required this.action});

  final DemoHelpAction action;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(action.label),
          const SizedBox(height: 2),
          Text(
            action.detail,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: action.style == DemoHelpStyle.primaryFilled
                  ? Colors.white.withValues(alpha: 0.9)
                  : CwcColors.sub,
            ),
          ),
        ],
      ),
    );

    switch (action.style) {
      case DemoHelpStyle.primaryFilled:
        return FilledButton(
          onPressed: () => showDemoOnlySnackBar(context, action.label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        );
      case DemoHelpStyle.blackOutline:
        return OutlinedButton(
          onPressed: () => showDemoOnlySnackBar(context, action.label),
          style: OutlinedButton.styleFrom(
            foregroundColor: CwcColors.neutralEmphasis,
            side: const BorderSide(
              color: CwcColors.neutralEmphasis,
              width: 1.5,
            ),
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        );
      case DemoHelpStyle.neutralOutline:
        return OutlinedButton(
          onPressed: () => showDemoOnlySnackBar(context, action.label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        );
    }
  }
}
