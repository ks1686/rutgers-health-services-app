import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import '../settings/shared_preferences_store.dart';
import 'wellness_goals.dart';

class WellnessGoalsScreen extends StatefulWidget {
  const WellnessGoalsScreen({super.key, this.store});

  final WellnessGoalsStore? store;

  @override
  State<WellnessGoalsScreen> createState() => _WellnessGoalsScreenState();
}

class _WellnessGoalsScreenState extends State<WellnessGoalsScreen> {
  WellnessGoalsStore? _store;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final injected = widget.store;
    if (injected != null) {
      setState(() => _store = injected);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final store = WellnessGoalsStore(SharedPreferencesStore(prefs));
    store.load();
    if (!mounted) return;
    setState(() => _store = store);
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness goals'),
        actions: const [HelpNowButton()],
      ),
      body: store == null
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final goals = store.goals;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const Text(
                      'Each one is optional. Nothing turns on by itself. '
                      'These are separate from Learn articles, and they are '
                      'not medication or appointment reminders.',
                      style: TextStyle(fontSize: 18, height: 1.4),
                    ),
                    if (goals.showCloseNudge) ...[
                      const SizedBox(height: 16),
                      const _NudgeBanner('You are close to your step goal.'),
                    ],
                    const SizedBox(height: 8),
                    _GoalSwitch(
                      switchKey: const ValueKey('wellness-water'),
                      title: 'Drink water',
                      subtitle: goals.water
                          ? 'On · around ${formatMinutes(goals.waterMinutes)}'
                          : 'Off',
                      value: goals.water,
                      onChanged: (value) =>
                          store.update(goals.copyWith(water: value)),
                    ),
                    _GoalSwitch(
                      switchKey: const ValueKey('wellness-breath'),
                      title: 'Pause for a breath',
                      subtitle: goals.breath
                          ? 'On · around ${formatMinutes(goals.breathMinutes)}'
                          : 'Off',
                      value: goals.breath,
                      onChanged: (value) =>
                          store.update(goals.copyWith(breath: value)),
                    ),
                    _GoalSwitch(
                      switchKey: const ValueKey('wellness-steps'),
                      title: 'Steps',
                      subtitle: goals.steps
                          ? 'On · goal ${goals.stepGoal}'
                          : 'Off',
                      value: goals.steps,
                      onChanged: (value) => store.update(
                        goals.copyWith(
                          steps: value,
                          nudgeWhenClose: value ? goals.nudgeWhenClose : false,
                        ),
                      ),
                    ),
                    if (goals.steps) ...[
                      const SizedBox(height: 4),
                      TextFormField(
                        key: const ValueKey('wellness-step-goal'),
                        initialValue: '${goals.stepGoal}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Personal step goal',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 18),
                        onFieldSubmitted: (raw) {
                          final parsed = int.tryParse(raw.trim());
                          if (parsed == null || parsed < 100) return;
                          store.update(goals.copyWith(stepGoal: parsed));
                        },
                      ),
                      const SizedBox(height: 8),
                      _GoalSwitch(
                        switchKey: const ValueKey('wellness-close-nudge'),
                        title: 'Nudge me when I am close',
                        subtitle: 'Shows in the app near your step goal',
                        value: goals.nudgeWhenClose,
                        onChanged: (value) =>
                            store.update(goals.copyWith(nudgeWhenClose: value)),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Steps today',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fewer steps',
                            onPressed: goals.stepsToday == 0
                                ? null
                                : () {
                                    final next = goals.stepsToday - 100;
                                    store.update(
                                      goals.copyWith(
                                        stepsToday: next < 0 ? 0 : next,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            '${goals.stepsToday}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          IconButton(
                            key: const ValueKey('wellness-steps-plus'),
                            tooltip: 'More steps',
                            onPressed: () => store.update(
                              goals.copyWith(
                                stepsToday: goals.stepsToday + 100,
                              ),
                            ),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                    _GoalSwitch(
                      switchKey: const ValueKey('wellness-sleep'),
                      title: 'A steady bedtime and wake time',
                      subtitle: goals.steadySleep
                          ? 'Wake ${formatMinutes(goals.wakeMinutes)} · '
                                'Bed ${formatMinutes(goals.bedMinutes)}'
                          : 'Off',
                      value: goals.steadySleep,
                      onChanged: (value) =>
                          store.update(goals.copyWith(steadySleep: value)),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _NudgeBanner extends StatelessWidget {
  const _NudgeBanner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CwcColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GoalSwitch extends StatelessWidget {
  const _GoalSwitch({
    required this.switchKey,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: switchKey,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 18,
          height: 1.35,
          color: CwcColors.sub,
        ),
      ),
      value: value,
      activeThumbColor: CwcColors.primary,
      onChanged: onChanged,
    );
  }
}
