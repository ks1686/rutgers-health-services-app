import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/link_launcher.dart';
import 'appointment_form_screen.dart';
import 'data/health_controller.dart';
import 'data/health_launchers.dart';
import 'data/health_models.dart';
import 'health_scope.dart';
import 'medication_form_screen.dart';
import 'provider_form_screen.dart';
import 'wallet_card_screen.dart';

class MyHealthScreen extends StatelessWidget {
  const MyHealthScreen({super.key, this.launcher});

  final LinkLauncher? launcher;

  Future<bool> _launch(Uri uri) {
    final custom = launcher;
    if (custom != null) return custom(uri);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openForm(BuildContext context, Widget page) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _promptSetPin(
    BuildContext context,
    HealthController health,
  ) async {
    final pin = await _askPin(
      context,
      title: 'Set a PIN for My Health',
      message:
          'Choose 4 to 8 digits. Nearby, Learn, and Help Now stay unlocked.',
    );
    if (pin == null || !context.mounted) return;
    final confirm = await _askPin(
      context,
      title: 'Confirm PIN',
      message: 'Enter the same PIN again.',
    );
    if (!context.mounted) return;
    if (confirm != pin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs did not match. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ok = await health.setPin(pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'PIN saved on this phone.' : 'PIN must be 4–8 digits.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _promptUnlock(
    BuildContext context,
    HealthController health,
  ) async {
    final pin = await _askPin(
      context,
      title: 'Enter your PIN',
      message: 'My Health is locked on this phone.',
    );
    if (pin == null || !context.mounted) return;
    final ok = await health.unlock(pin);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That PIN did not match.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _askPin(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final health = HealthScope.of(context);
    return ListenableBuilder(
      listenable: health,
      builder: (context, _) {
        if (!health.ready) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!health.isUnlocked) {
          return _PinLockView(onUnlock: () => _promptUnlock(context, health));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _PrivacyBanner(
              hasPin: health.hasPin,
              onSetPin: () => _promptSetPin(context, health),
              onLock: health.hasPin ? health.lock : null,
              onClearPin: health.hasPin
                  ? () async {
                      await health.clearPin();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PIN removed from this phone.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Appointments',
              onAdd: () => _openForm(context, const AppointmentFormScreen()),
              children: [
                if (health.appointments.isEmpty)
                  const _EmptyHint('No appointments yet. Tap Add.'),
                for (final appt in health.appointments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(appt.provider),
                    subtitle: Text(
                      '${appt.whenLabel}\n${appt.location}'
                      '${appt.note != null ? '\n${appt.note}' : ''}',
                    ),
                    isThreeLine: true,
                    onTap: () => _openForm(
                      context,
                      AppointmentFormScreen(existing: appt),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Medications',
              onAdd: () => _openForm(context, const MedicationFormScreen()),
              children: [
                if (health.medications.isEmpty)
                  const _EmptyHint('No medications yet. Tap Add.'),
                for (final med in health.medications)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(med.name),
                    subtitle: Text('${med.purpose}\n${med.schedule}'),
                    isThreeLine: true,
                    onTap: () =>
                        _openForm(context, MedicationFormScreen(existing: med)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Providers & Portals',
              onAdd: () => _openForm(context, const ProviderFormScreen()),
              children: [
                if (health.providers.isEmpty)
                  const _EmptyHint('No providers yet. Tap Add.'),
                for (final provider in health.providers)
                  _ProviderTile(
                    provider: provider,
                    onEdit: () => _openForm(
                      context,
                      ProviderFormScreen(existing: provider),
                    ),
                    onCall: () => _launch(healthTelUri(provider.phone)),
                    onText: () => _launch(healthSmsUri(provider.phone)),
                    onPortal: provider.portalUrl == null
                        ? null
                        : () {
                            final uri = healthPortalUri(provider.portalUrl);
                            if (uri == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'That portal address does not look right.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            _launch(uri);
                          },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WalletCardScreen(launcher: launcher),
                  ),
                );
              },
              icon: const Icon(Icons.wallet_outlined),
              label: const Text('Show My Wallet Card'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Works offline — show this at an appointment',
              textAlign: TextAlign.center,
              style: TextStyle(color: CwcColors.sub, fontSize: 16),
            ),
          ],
        );
      },
    );
  }
}

class _PinLockView extends StatelessWidget {
  const _PinLockView({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: CwcColors.primary),
          const SizedBox(height: 16),
          const Text(
            'My Health is locked',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your PIN to see appointments, medications, and providers. '
            'Help Now stays available.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CwcColors.sub),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onUnlock, child: const Text('Enter PIN')),
        ],
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({
    required this.hasPin,
    required this.onSetPin,
    this.onLock,
    this.onClearPin,
  });

  final bool hasPin;
  final VoidCallback onSetPin;
  final VoidCallback? onLock;
  final VoidCallback? onClearPin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CwcColors.primaryTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasPin
                ? 'Protected by your PIN — stored encrypted on this phone.'
                : 'Your info stays encrypted on this phone. You can add an optional PIN.',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (!hasPin)
                TextButton(onPressed: onSetPin, child: const Text('Set PIN')),
              if (onLock != null)
                TextButton(onPressed: onLock, child: const Text('Lock now')),
              if (onClearPin != null)
                TextButton(
                  onPressed: onClearPin,
                  child: const Text('Remove PIN'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: CwcColors.sub)),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.onEdit,
    required this.onCall,
    required this.onText,
    this.onPortal,
  });

  final HealthProvider provider;
  final VoidCallback onEdit;
  final VoidCallback onCall;
  final VoidCallback onText;
  final VoidCallback? onPortal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(provider.name),
          subtitle: Text(
            '${provider.role}'
            '${provider.portalLabel != null ? ' · ${provider.portalLabel}' : ''}',
          ),
          onTap: onEdit,
        ),
        Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Call',
              icon: const Icon(Icons.phone_outlined),
              onPressed: onCall,
            ),
            IconButton(
              tooltip: 'Text',
              icon: const Icon(Icons.sms_outlined),
              onPressed: onText,
            ),
            if (onPortal != null)
              IconButton(
                tooltip: 'Open portal',
                icon: const Icon(Icons.open_in_new),
                onPressed: onPortal,
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
