import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import 'app_preferences.dart';

String _textSizeLabel(TextSizeChoice choice) {
  return switch (choice) {
    TextSizeChoice.system => 'Match phone',
    TextSizeChoice.large => 'Large',
    TextSizeChoice.extraLarge => 'Extra large',
  };
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _town;
  var _seededTown = false;

  @override
  void initState() {
    super.initState();
    _town = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededTown) return;
    _seededTown = true;
    _town.text = AppPreferencesScope.of(context).rememberedTown;
  }

  @override
  void dispose() {
    _town.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferencesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Text size', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'This is added on top of the text size in your phone settings.',
            style: TextStyle(fontSize: 18, height: 1.4, color: CwcColors.sub),
          ),
          const SizedBox(height: 12),
          Wrap(
            key: const ValueKey('settings-text-size'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in TextSizeChoice.values)
                ChoiceChip(
                  label: Text(_textSizeLabel(choice)),
                  labelStyle: const TextStyle(
                    fontSize: 18,
                    color: CwcColors.ink,
                  ),
                  selected: prefs.textSize == choice,
                  onSelected: (selected) {
                    if (selected) prefs.setTextSize(choice);
                  },
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Town', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Nearby uses this town when you are not using your location.',
            style: TextStyle(fontSize: 18, height: 1.4, color: CwcColors.sub),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('settings-town'),
            controller: _town,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Town',
              hintText: 'New Brunswick',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('settings-save-town'),
            onPressed: () async {
              await prefs.setRememberedTown(_town.text);
              if (!context.mounted) return;
              final saved = prefs.rememberedTown;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    saved.isEmpty
                        ? 'Nearby will use its usual town.'
                        : 'Nearby will remember $saved.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save town'),
          ),
          const SizedBox(height: 28),
          const Text(
            'A PIN for My Health is set on the My Health tab. Settings does not change it.',
            style: TextStyle(fontSize: 18, height: 1.4, color: CwcColors.ink),
          ),
        ],
      ),
    );
  }
}
