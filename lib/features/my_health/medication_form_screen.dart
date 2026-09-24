import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import 'data/health_controller.dart';
import 'data/health_models.dart';
import 'data/reminder_plan.dart';
import 'health_scope.dart';
import 'reminder_pickers.dart';

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({super.key, this.existing});

  final HealthMedication? existing;

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _purpose;
  late final TextEditingController _schedule;
  late bool _remind;
  late List<int> _remindMinutes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _purpose = TextEditingController(text: e?.purpose ?? '');
    _schedule = TextEditingController(text: e?.schedule ?? '');
    _remind = e?.remind ?? false;
    _remindMinutes = List<int>.of(e?.remindMinutes ?? const []);
  }

  @override
  void dispose() {
    _name.dispose();
    _purpose.dispose();
    _schedule.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = HealthScope.of(context);
    final minutes = _remindMinutes.isEmpty
        ? inferReminderMinutes(_schedule.text)
        : normalizeReminderMinutes(_remindMinutes);
    if (_remind) {
      final allowed = await controller.requestReminderPermission();
      if (!allowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reminder saved. Allow notifications in More so this phone can alert you.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (!mounted) return;
    final id = widget.existing?.id ?? HealthController.newId();
    await controller.upsertMedication(
      HealthMedication(
        id: id,
        name: _name.text.trim(),
        purpose: _purpose.text.trim(),
        schedule: _schedule.text.trim(),
        remind: _remind,
        remindMinutes: minutes,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _changeMinute(int minute) async {
    final picked = await pickMinuteOfDay(context, initial: minute);
    if (picked == null || !mounted) return;
    setState(() {
      _remindMinutes = normalizeReminderMinutes([
        for (final existing in _remindMinutes)
          if (existing != minute) existing,
        picked,
      ]);
    });
  }

  Future<void> _addMinute() async {
    final picked = await pickMinuteOfDay(context, initial: 8 * 60);
    if (picked == null || !mounted) return;
    setState(() {
      _remindMinutes = normalizeReminderMinutes([..._remindMinutes, picked]);
    });
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medication?'),
        content: const Text(
          'This is only a memory aid on this phone — not medical advice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await HealthScope.of(context).deleteMedication(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit medication' : 'Add medication'),
        actions: const [HelpNowButton()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'A personal memory aid — not medical advice.',
              style: TextStyle(color: CwcColors.sub, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Medication name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _purpose,
              decoration: const InputDecoration(
                labelText: "What it's for (your words)",
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter what it is for'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _schedule,
              decoration: const InputDecoration(
                labelText: 'Dose / schedule',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a schedule' : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me on this phone'),
              subtitle: const Text(
                'Uses this medication. The alert stays on this phone and works offline.',
                style: TextStyle(color: CwcColors.sub, fontSize: 14),
              ),
              value: _remind,
              onChanged: (v) => setState(() {
                _remind = v;
                if (v && _remindMinutes.isEmpty) {
                  _remindMinutes = inferReminderMinutes(_schedule.text);
                }
              }),
            ),
            if (_remind) ...[
              for (final minute in _remindMinutes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Remind me at ${formatMinuteOfDay(minute)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Change time',
                        onPressed: () => _changeMinute(minute),
                        icon: const Icon(Icons.schedule),
                      ),
                      if (_remindMinutes.length > 1)
                        IconButton(
                          tooltip: 'Remove time',
                          onPressed: () => setState(() {
                            _remindMinutes = [
                              for (final existing in _remindMinutes)
                                if (existing != minute) existing,
                            ];
                          }),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addMinute,
                  icon: const Icon(Icons.add),
                  label: const Text('Add another time'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
            if (editing) ...[
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _delete, child: const Text('Delete')),
            ],
          ],
        ),
      ),
    );
  }
}
