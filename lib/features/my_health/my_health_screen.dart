import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/link_launcher.dart';
import '../settings/app_preferences.dart';
import 'appointment_form_screen.dart';
import 'data/health_controller.dart';
import 'data/health_launchers.dart';
import 'data/health_models.dart';
import 'document_form_screen.dart';
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

  List<Widget> _visibleRecords({
    required bool hiding,
    required bool isEmpty,
    required String emptyHint,
    required List<Widget> records,
  }) {
    if (hiding) {
      return const [_EmptyHint('Hidden while someone is helping you.')];
    }
    if (isEmpty) return [_EmptyHint(emptyHint)];
    return records;
  }

  @override
  Widget build(BuildContext context) {
    final health = HealthScope.of(context);
    final hiding = AppPreferencesScope.maybeOf(context)?.helperHiding ?? false;
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
              children: _visibleRecords(
                hiding: hiding,
                isEmpty: health.appointments.isEmpty,
                emptyHint: 'No appointments yet. Tap Add.',
                records: [
                  for (final appt in health.appointments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(appt.provider),
                      subtitle: Text(
                        '${appt.whenLabel}\n${appt.location}'
                        '${appt.note != null ? '\n${appt.note}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: appt.remind
                          ? const Tooltip(
                              message: 'Reminder on',
                              child: Icon(Icons.notifications_active_outlined),
                            )
                          : null,
                      onTap: () => _openForm(
                        context,
                        AppointmentFormScreen(existing: appt),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Medications',
              onAdd: () => _openForm(context, const MedicationFormScreen()),
              children: _visibleRecords(
                hiding: hiding,
                isEmpty: health.medications.isEmpty,
                emptyHint: 'No medications yet. Tap Add.',
                records: [
                  for (final med in health.medications)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(med.name),
                      subtitle: Text('${med.purpose}\n${med.schedule}'),
                      isThreeLine: true,
                      trailing: med.remind
                          ? const Tooltip(
                              message: 'Reminder on',
                              child: Icon(Icons.notifications_active_outlined),
                            )
                          : null,
                      onTap: () => _openForm(
                        context,
                        MedicationFormScreen(existing: med),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Providers & Portals',
              onAdd: () => _openForm(context, const ProviderFormScreen()),
              children: _visibleRecords(
                hiding: hiding,
                isEmpty: health.providers.isEmpty,
                emptyHint: 'No providers yet. Tap Add.',
                records: [
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
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Personal papers',
              onAdd: () => _openForm(context, const DocumentFormScreen()),
              addButtonKey: const ValueKey('add-personal-paper'),
              children: [
                const Text(
                  'Only on this phone. A psychiatric advance directive, '
                  'living will, service or support animal note, RAT plan, '
                  'or Charge It workbook.',
                  style: TextStyle(color: CwcColors.sub),
                ),
                const SizedBox(height: 8),
                if (health.documents.isEmpty)
                  const _EmptyHint('No personal papers yet. Tap Add.'),
                for (final paper in health.documents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(paper.title),
                    subtitle: Text(
                      paper.hasFile
                          ? '${paper.kind.label}\n${paper.fileName}'
                          : paper.kind.label,
                    ),
                    isThreeLine: paper.hasFile,
                    onTap: () =>
                        _openForm(context, DocumentFormScreen(existing: paper)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _EmergencyCardChoices(health: health),
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

class _EmergencyCardChoices extends StatelessWidget {
  const _EmergencyCardChoices({required this.health});

  final HealthController health;

  Future<void> _set(
    EmergencyCardChoices Function(EmergencyCardChoices current) change,
  ) {
    return health.updateEmergencyCard(change(health.emergencyCard));
  }

  @override
  Widget build(BuildContext context) {
    final choices = health.emergencyCard;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency card',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Everything here starts off. Help Now can show only what you '
              'turn on, without opening the rest of My Health. Anyone with '
              'this phone can see those items. The rest stays behind your PIN.',
              style: TextStyle(color: CwcColors.sub, height: 1.35),
            ),
            _ChoiceSwitch(
              label: 'Emergency contact',
              value: choices.showEmergencyContact,
              onChanged: (on) =>
                  _set((c) => c.copyWith(showEmergencyContact: on)),
            ),
            _ChoiceSwitch(
              label: 'Conditions',
              value: choices.showConditions,
              onChanged: (on) => _set((c) => c.copyWith(showConditions: on)),
            ),
            _ChoiceSwitch(
              label: 'Medications',
              value: choices.showMedications,
              onChanged: (on) => _set((c) => c.copyWith(showMedications: on)),
            ),
            _ChoiceSwitch(
              label: 'Providers',
              value: choices.showProviders,
              onChanged: (on) => _set((c) => c.copyWith(showProviders: on)),
            ),
            _ChoiceSwitch(
              label: 'Appointment notes',
              value: choices.showAppointmentNotes,
              onChanged: (on) =>
                  _set((c) => c.copyWith(showAppointmentNotes: on)),
            ),
            _ChoiceSwitch(
              label: 'Psychiatric advance directive',
              value: choices.showPsychiatricAdvanceDirective,
              onChanged: (on) =>
                  _set((c) => c.copyWith(showPsychiatricAdvanceDirective: on)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceSwitch extends StatelessWidget {
  const _ChoiceSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
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
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
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
    this.addButtonKey,
  });

  final String title;
  final VoidCallback onAdd;
  final List<Widget> children;
  final Key? addButtonKey;

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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: addButtonKey,
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
