import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/demo_help_now.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/demo_snackbar.dart';
import '../../widgets/link_launcher.dart';
import '../my_health/health_scope.dart';
import 'help_now_config.dart';

const helpNowEmergencyCardPref = 'cwc_help_now_show_emergency_card';

class HelpNowScreen extends StatefulWidget {
  const HelpNowScreen({super.key, this.config, this.launcher});

  final HelpNowConfig? config;
  final LinkLauncher? launcher;

  @override
  State<HelpNowScreen> createState() => _HelpNowScreenState();
}

class _HelpNowScreenState extends State<HelpNowScreen> {
  bool _showEmergencyCard = false;
  bool _cardPrefReady = false;

  HelpNowConfig get _config => widget.config ?? HelpNowConfig.fromEnvironment();

  @override
  void initState() {
    super.initState();
    _loadCardPref();
  }

  Future<void> _loadCardPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showEmergencyCard = prefs.getBool(helpNowEmergencyCardPref) ?? false;
      _cardPrefReady = true;
    });
  }

  Future<void> _setShowCard(bool value) async {
    setState(() => _showEmergencyCard = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(helpNowEmergencyCardPref, value);
  }

  Future<void> _open(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final launcher = widget.launcher ?? _launchExternal;
    final opened = await launcher(uri);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open that on this phone.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onAction(DemoHelpAction action) {
    final uri = action.callUri ?? action.textUri;
    if (uri != null) {
      _open(uri);
      return;
    }
    showDemoOnlySnackBar(context, action.label);
  }

  @override
  Widget build(BuildContext context) {
    final live = _config.helpNowLive;
    final actions = helpNowActions(live: live);
    final emergency = [
      for (final action in actions)
        if (action.section == HelpNowSection.emergency) action,
    ];
    final additional = [
      for (final action in actions)
        if (action.section == HelpNowSection.additional) action,
    ];
    final health = HealthScope.maybeOf(context);

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
          Text(
            live
                ? 'One tap fills the phone number. You place the call. '
                      '911, 988, Poison Control, ReachNJ, and the Clearinghouse '
                      'can call or text from this phone. The Wellness Center '
                      'and peer warmline are still sample numbers.'
                : 'One tap to reach support. These buttons are demo-only '
                      '(they do not place calls or texts yet).',
            style: const TextStyle(
              color: CwcColors.sub,
              height: 1.4,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          if (_cardPrefReady)
            _EmergencyCardBlock(
              showCard: _showEmergencyCard,
              onChanged: _setShowCard,
              contact: health?.wallet.emergencyContact ?? '',
              conditions: health?.wallet.conditions ?? '',
              medications: [
                for (final med in health?.medications ?? const []) med.name,
              ],
            ),
          const SizedBox(height: 20),
          const _SectionLabel('Emergency'),
          const SizedBox(height: 8),
          for (final action in emergency) ...[
            _HelpActionButton(
              action: action,
              onPressed: () => _onAction(action),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          const _SectionLabel('Additional support'),
          const SizedBox(height: 8),
          for (final action in additional) ...[
            _HelpActionButton(
              action: action,
              onPressed: () => _onAction(action),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: CwcColors.ink,
      ),
    );
  }
}

class _EmergencyCardBlock extends StatelessWidget {
  const _EmergencyCardBlock({
    required this.showCard,
    required this.onChanged,
    required this.contact,
    required this.conditions,
    required this.medications,
  });

  final bool showCard;
  final ValueChanged<bool> onChanged;
  final String contact;
  final String conditions;
  final List<String> medications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Show my emergency card here',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            showCard
                ? 'Wallet details from My Health are visible on this unlocked screen.'
                : 'Off by default — turning this on shares health info on an unlocked screen.',
            style: const TextStyle(
              color: CwcColors.sub,
              fontSize: 16,
              height: 1.35,
            ),
          ),
          value: showCard,
          activeThumbColor: CwcColors.primary,
          onChanged: onChanged,
        ),
        if (showCard)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CwcColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CwcColors.line),
            ),
            child: Text(
              _previewCopy(contact, conditions, medications),
              style: const TextStyle(height: 1.4, fontSize: 18),
            ),
          ),
      ],
    );
  }

  static String _previewCopy(
    String contact,
    String conditions,
    List<String> medications,
  ) {
    final contactLine = contact.isEmpty ? 'None saved yet' : contact;
    final conditionLine = conditions.isEmpty ? 'None saved yet' : conditions;
    final medsLine = medications.isEmpty
        ? 'None saved yet'
        : medications.join(', ');
    return 'Emergency card\n'
        'Contact: $contactLine\n'
        'Conditions: $conditionLine\n'
        'Medications: $medsLine';
  }
}

class _HelpActionButton extends StatelessWidget {
  const _HelpActionButton({required this.action, required this.onPressed});

  final DemoHelpAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isEmergency = action.style == DemoHelpStyle.emergencyFilled;
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isEmergency ? 22 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.detail,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.3,
              color: _detailColor(action.style),
            ),
          ),
        ],
      ),
    );

    switch (action.style) {
      case DemoHelpStyle.emergencyFilled:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: CwcColors.neutralEmphasis,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: child,
        );
      case DemoHelpStyle.primaryFilled:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        );
      case DemoHelpStyle.blackOutline:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: CwcColors.neutralEmphasis,
            side: const BorderSide(
              color: CwcColors.neutralEmphasis,
              width: 1.5,
            ),
            minimumSize: const Size.fromHeight(64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        );
      case DemoHelpStyle.neutralOutline:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        );
    }
  }

  Color _detailColor(DemoHelpStyle style) {
    switch (style) {
      case DemoHelpStyle.emergencyFilled:
      case DemoHelpStyle.primaryFilled:
        return Colors.white.withValues(alpha: 0.92);
      case DemoHelpStyle.blackOutline:
      case DemoHelpStyle.neutralOutline:
        return CwcColors.sub;
    }
  }
}
