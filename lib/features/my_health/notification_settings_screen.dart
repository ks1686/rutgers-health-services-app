import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import 'data/health_models.dart';
import 'data/reminder_plan.dart';
import 'health_scope.dart';
import 'reminder_pickers.dart';

/// Notification controls for reminders already saved in My Health.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool? _allowed;
  var _loadedPermission = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedPermission) return;
    _loadedPermission = true;
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final allowed = await HealthScope.of(context).remindersAllowed();
    if (mounted) setState(() => _allowed = allowed);
  }

  Future<void> _allow() async {
    final health = HealthScope.of(context);
    final ok = await health.requestReminderPermission(precise: true);
    if (mounted) setState(() => _allowed = ok);
  }

  Future<void> _setMedication(HealthMedication med, bool on) async {
    final health = HealthScope.of(context);
    if (on) await health.requestReminderPermission();
    if (!mounted) return;
    final minutes = med.remindMinutes.isNotEmpty
        ? med.remindMinutes
        : inferReminderMinutes(med.schedule);
    await health.upsertMedication(
      med.copyWith(remind: on, remindMinutes: minutes),
    );
  }

  List<int> _minutes(HealthMedication med) {
    return med.remindMinutes.isEmpty
        ? inferReminderMinutes(med.schedule)
        : med.remindMinutes;
  }

  Future<void> _changeMedicationTime(HealthMedication med, int minute) async {
    final picked = await pickMinuteOfDay(context, initial: minute);
    if (picked == null || !mounted) return;
    final next = normalizeReminderMinutes([
      for (final existing in _minutes(med))
        if (existing != minute) existing,
      picked,
    ]);
    await HealthScope.of(
      context,
    ).upsertMedication(med.copyWith(remind: true, remindMinutes: next));
  }

  Future<void> _addMedicationTime(HealthMedication med) async {
    final picked = await pickMinuteOfDay(context, initial: 8 * 60);
    if (picked == null || !mounted) return;
    await HealthScope.of(context).upsertMedication(
      med.copyWith(
        remind: true,
        remindMinutes: normalizeReminderMinutes([..._minutes(med), picked]),
      ),
    );
  }

  Future<void> _setAppointment(HealthAppointment appt, bool on) async {
    final health = HealthScope.of(context);
    if (on) await health.requestReminderPermission();
    if (!mounted) return;
    final remindAt =
        appt.remindAt ?? appt.when ?? parseAppointmentWhen(appt.whenLabel);
    if (on && remindAt == null) {
      final picked = await pickLocalDateTime(
        context,
        initial: DateTime.now().add(const Duration(hours: 1)),
      );
      if (picked == null || !mounted) return;
      await health.upsertAppointment(
        appt.copyWith(remind: true, remindAt: picked),
      );
      return;
    }
    await health.upsertAppointment(
      appt.copyWith(remind: on, remindAt: remindAt),
    );
  }

  Future<void> _changeAppointmentTime(HealthAppointment appt) async {
    final initial =
        appt.remindAt ??
        appt.when ??
        DateTime.now().add(const Duration(hours: 1));
    final picked = await pickLocalDateTime(context, initial: initial);
    if (picked == null || !mounted) return;
    await HealthScope.of(
      context,
    ).upsertAppointment(appt.copyWith(remind: true, remindAt: picked));
  }

  @override
  Widget build(BuildContext context) {
    final health = HealthScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: const [HelpNowButton()],
      ),
      body: ListenableBuilder(
        listenable: health,
        builder: (context, _) {
          final meds = health.medications;
          final appointments = health.appointments;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text(
                'Reminders use the medications and appointments already in '
                'My Health. They stay on this phone and work with no internet. '
                'Nothing is sent to a server.',
                style: TextStyle(color: CwcColors.sub, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (_allowed == false) ...[
                const Text(
                  'Notifications are off. Allow them so this phone can alert you. '
                  'On Android you can also allow exact alarms so the alert '
                  'arrives at the time you chose.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _allow,
                  child: const Text('Allow notifications'),
                ),
                const SizedBox(height: 16),
              ] else if (_allowed == true) ...[
                const Text(
                  'Notifications are on for this phone.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Medications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (meds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Save a medication in My Health first.'),
                ),
              for (final med in meds) ...[
                SwitchListTile(
                  key: ValueKey('reminder-med-${med.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(med.name),
                  subtitle: Text(med.schedule),
                  value: med.remind,
                  onChanged: (on) => _setMedication(med, on),
                ),
                if (med.remind)
                  for (final minute in _minutes(med))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(formatMinuteOfDay(minute)),
                      trailing: IconButton(
                        tooltip: 'Change time',
                        onPressed: () => _changeMedicationTime(med, minute),
                        icon: const Icon(Icons.schedule),
                      ),
                    ),
                if (med.remind)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addMedicationTime(med),
                      icon: const Icon(Icons.add),
                      label: const Text('Add another time'),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                'Appointments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (appointments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Save an appointment in My Health first.'),
                ),
              for (final appt in appointments) ...[
                SwitchListTile(
                  key: ValueKey('reminder-appt-${appt.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(appt.provider),
                  subtitle: Text(appt.whenLabel),
                  value: appt.remind,
                  onChanged: (on) => _setAppointment(appt, on),
                ),
                if (appt.remind)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _appointmentFireLabel(appt) ?? 'Choose a reminder time',
                    ),
                    subtitle: const Text(
                      'Change when the alert fires. The visit stays as saved.',
                    ),
                    trailing: IconButton(
                      tooltip: 'Change reminder time',
                      onPressed: () => _changeAppointmentTime(appt),
                      icon: const Icon(Icons.schedule),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  String? _appointmentFireLabel(HealthAppointment appt) {
    final fire =
        appt.remindAt ?? appt.when ?? parseAppointmentWhen(appt.whenLabel);
    if (fire == null) return null;
    return formatAppointmentWhen(fire);
  }
}
