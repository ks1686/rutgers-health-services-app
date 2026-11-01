import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../links/phone_links.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import '../../widgets/link_launcher.dart';
import 'data/health_controller.dart';
import 'data/health_models.dart';
import 'health_scope.dart';
import 'save_feedback.dart';
import 'visible_health.dart';

class WalletCardScreen extends StatelessWidget {
  const WalletCardScreen({super.key, this.launcher});

  final LinkLauncher? launcher;

  Future<bool> _launch(Uri uri) {
    final custom = launcher;
    if (custom != null) return custom(uri);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _editWallet(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _WalletEditDialog(health: HealthScope.of(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final health = HealthScope.of(context);
    return ListenableBuilder(
      listenable: health,
      builder: (context, _) {
        final visible = VisibleHealth.of(context);
        final hiding = visible.hidden;
        final meds = visible.medications;
        final providers = visible.providers;
        final wallet = visible.wallet;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Wallet Card'),
            actions: [
              if (!hiding)
                IconButton(
                  tooltip: 'Edit wallet details',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editWallet(context),
                ),
              const HelpNowButton(),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: CwcColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, height: 1.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Health Snapshot',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Works offline · on this phone only',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        if (hiding)
                          const Text(
                            '$kHelperHiddenHint Your own information is still saved on this phone.',
                            style: TextStyle(fontSize: 18, height: 1.4),
                          )
                        else ...[
                          const Text(
                            'Medications',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (meds.isEmpty)
                            const Text('None saved yet')
                          else
                            for (final med in meds)
                              Text('• ${med.name} - ${med.purpose}'),
                          const SizedBox(height: 12),
                          const Text(
                            'Providers',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (providers.isEmpty)
                            const Text('None saved yet')
                          else
                            for (final provider in providers)
                              Text('• ${provider.name} (${provider.phone})'),
                          const SizedBox(height: 12),
                          const Text(
                            'Emergency contact',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            wallet.emergencyContact.isEmpty
                                ? 'None saved yet'
                                : wallet.emergencyContact,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Conditions (optional)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            wallet.conditions.isEmpty
                                ? 'None saved yet'
                                : wallet.conditions,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Service or support animal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            wallet.serviceAnimal.isEmpty
                                ? 'None saved yet'
                                : wallet.serviceAnimal,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (providers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Quick call',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                for (final provider in providers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(provider.name),
                    trailing: IconButton(
                      tooltip: 'Call ${provider.name}',
                      icon: const Icon(Icons.phone_outlined),
                      onPressed: () => _launch(phoneTelUri(provider.phone)),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Edits the wallet details. Saves from the Save button and closes only once
/// the phone has kept them, so a failed save keeps everything typed.
class _WalletEditDialog extends StatefulWidget {
  const _WalletEditDialog({required this.health});

  final HealthController health;

  @override
  State<_WalletEditDialog> createState() => _WalletEditDialogState();
}

class _WalletEditDialogState extends State<_WalletEditDialog> {
  late final _contact = TextEditingController(
    text: widget.health.wallet.emergencyContact,
  );
  late final _conditions = TextEditingController(
    text: widget.health.wallet.conditions,
  );
  late final _serviceAnimal = TextEditingController(
    text: widget.health.wallet.serviceAnimal,
  );
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _contact.dispose();
    _conditions.dispose();
    _serviceAnimal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    final ok = await widget.health.updateWallet(
      HealthWallet(
        emergencyContact: _contact.text.trim(),
        conditions: _conditions.text.trim(),
        serviceAnimal: _serviceAnimal.text.trim(),
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wallet details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _contact,
              decoration: const InputDecoration(
                labelText: 'Emergency contact',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conditions,
              decoration: const InputDecoration(
                labelText: 'Conditions (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serviceAnimal,
              decoration: const InputDecoration(
                labelText: 'Service or support animal',
                hintText: 'Type of animal, name, anything a helper should know',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (_failed) ...[
              const SizedBox(height: 12),
              const Text(
                kCouldNotSaveMessage,
                key: ValueKey('wallet-save-failed'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CwcColors.ink,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
