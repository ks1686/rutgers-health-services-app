import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import 'data/health_controller.dart';
import 'data/health_models.dart';
import 'data/reminder_plan.dart';
import 'health_scope.dart';
import 'reminder_pickers.dart';

class AppointmentFormScreen extends StatefulWidget {
  const AppointmentFormScreen({super.key, this.existing});

  final HealthAppointment? existing;

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _provider;
  late final TextEditingController _when;
  late final TextEditingController _location;
  late final TextEditingController _phone;
  late final TextEditingController _note;
  late bool _remind;
  DateTime? _whenAt;
  DateTime? _remindAt;
  bool _remindTimeCustom = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _provider = TextEditingController(text: e?.provider ?? '');
    _when = TextEditingController(text: e?.whenLabel ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _remind = e?.remind ?? false;
    if (e != null) {
      _whenAt = e.when ?? parseAppointmentWhen(e.whenLabel);
      _remindAt = e.remindAt ?? _whenAt;
      _remindTimeCustom =
          e.remindAt != null && (e.when == null || e.remindAt != e.when);
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    _when.dispose();
    _location.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final picked = await pickLocalDateTime(
      context,
      initial: _whenAt ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final previous = _whenAt;
      _whenAt = picked;
      _when.text = formatAppointmentWhen(picked);
      if (!_remindTimeCustom || _remindAt == null || _remindAt == previous) {
        _remindAt = picked;
      }
    });
  }

  Future<void> _pickRemindAt() async {
    final picked = await pickLocalDateTime(
      context,
      initial:
          _remindAt ?? _whenAt ?? DateTime.now().add(const Duration(hours: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _remindAt = picked;
      _remindTimeCustom = true;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = HealthScope.of(context);
    final whenAt = parseAppointmentWhen(_when.text.trim()) ?? _whenAt;
    var remindAt = _remindAt ?? whenAt;
    if (_remind && remindAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose when this reminder should fire.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
    await controller.upsertAppointment(
      HealthAppointment(
        id: id,
        provider: _provider.text.trim(),
        whenLabel: _when.text.trim(),
        location: _location.text.trim(),
        phone: _phone.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        remind: _remind,
        when: whenAt,
        remindAt: remindAt,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete appointment?'),
        content: const Text('This removes it from this phone only.'),
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
    await HealthScope.of(context).deleteAppointment(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit appointment' : 'Add appointment'),
        actions: const [HelpNowButton()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextFormField(
              controller: _provider,
              decoration: const InputDecoration(
                labelText: 'Provider or visit name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _when,
              decoration: InputDecoration(
                labelText: 'Date and time',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Pick date and time',
                  onPressed: _pickWhen,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter when' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a location' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
              ],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a phone' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me on this phone'),
              subtitle: const Text(
                'Uses this appointment. The alert stays on this phone and works offline.',
                style: TextStyle(color: CwcColors.sub, fontSize: 14),
              ),
              value: _remind,
              onChanged: (v) => setState(() {
                _remind = v;
                if (v && _remindAt == null) {
                  _remindAt =
                      parseAppointmentWhen(_when.text.trim()) ?? _whenAt;
                }
              }),
            ),
            if (_remind)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: _pickRemindAt,
                title: Text(
                  _remindAt == null
                      ? 'Choose when to remind you'
                      : 'Reminder: ${formatAppointmentWhen(_remindAt!)}',
                ),
                subtitle: Text(
                  _remindAt != null && !_remindAt!.isAfter(DateTime.now())
                      ? 'That time has already passed, so this phone will not alert.'
                      : 'You do not type this appointment again.',
                  style: const TextStyle(color: CwcColors.sub, fontSize: 14),
                ),
                trailing: IconButton(
                  tooltip: 'Change reminder time',
                  onPressed: _pickRemindAt,
                  icon: const Icon(Icons.schedule),
                ),
              ),
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
