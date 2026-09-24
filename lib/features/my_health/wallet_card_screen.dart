import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import '../../widgets/link_launcher.dart';
import '../settings/app_preferences.dart';
import 'data/health_launchers.dart';
import 'data/health_models.dart';
import 'health_scope.dart';

class WalletCardScreen extends StatelessWidget {
  const WalletCardScreen({super.key, this.launcher});

  final LinkLauncher? launcher;

  Future<bool> _launch(Uri uri) {
    final custom = launcher;
    if (custom != null) return custom(uri);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _editWallet(BuildContext context) async {
    final health = HealthScope.of(context);
    final contact = TextEditingController(text: health.wallet.emergencyContact);
    final conditions = TextEditingController(text: health.wallet.conditions);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wallet details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contact,
                decoration: const InputDecoration(
                  labelText: 'Emergency contact',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conditions,
                decoration: const InputDecoration(
                  labelText: 'Conditions (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      await health.updateWallet(
        HealthWallet(
          emergencyContact: contact.text.trim(),
          conditions: conditions.text.trim(),
        ),
      );
    }
    contact.dispose();
    conditions.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = HealthScope.of(context);
    final hiding = AppPreferencesScope.maybeOf(context)?.helperHiding ?? false;
    return ListenableBuilder(
      listenable: health,
      builder: (context, _) {
        final meds = health.medications;
        final providers = health.providers;
        final wallet = health.wallet;
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
                            'Hidden while someone is helping you. Your own information is still saved on this phone.',
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
                              Text('• ${med.name} — ${med.purpose}'),
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
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (!hiding && providers.isNotEmpty) ...[
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
                      onPressed: () => _launch(healthTelUri(provider.phone)),
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
