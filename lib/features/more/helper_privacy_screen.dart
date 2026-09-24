import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import '../settings/app_preferences.dart';

/// Hides real health details while a person gets help tapping through the app.
///
/// This is not a practice mode and does not load sample records.
class HelperPrivacyScreen extends StatelessWidget {
  const HelperPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferencesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Helper Mode'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Turn this on before a family member or friend helps you use the app. '
            'While it is on, they do not see your conditions or other private '
            'health details. Turn it off and your own information shows again. '
            'Your saved information stays on this phone. This does not replace '
            'My Health with sample records.',
            style: TextStyle(fontSize: 18, height: 1.4),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const ValueKey('helper-hide-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Hide my health details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              prefs.helperHiding
                  ? 'On. Health details are hidden.'
                  : 'Off. Your health details are visible after any PIN.',
              style: const TextStyle(
                fontSize: 18,
                height: 1.35,
                color: CwcColors.sub,
              ),
            ),
            value: prefs.helperHiding,
            activeThumbColor: CwcColors.primary,
            onChanged: prefs.setHelperHiding,
          ),
        ],
      ),
    );
  }
}
