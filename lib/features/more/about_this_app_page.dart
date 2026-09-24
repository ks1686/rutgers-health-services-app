import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';

/// General disclaimer people can open again from More (#31).
const kAboutThisAppParagraphs = <String>[
  'This app helps you keep health information in one place on your phone, '
      'and find places and phone numbers nearby. It is not a medical service.',
  'It does not replace professional care or seeing a doctor.',
  'Health information stays on this phone. We do not keep a copy.',
  'Nearby listings come from public maps. Our team does not check each '
      'place one by one.',
];

class AboutThisAppPage extends StatelessWidget {
  const AboutThisAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About this app'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final paragraph in kAboutThisAppParagraphs) ...[
            Text(
              paragraph,
              style: const TextStyle(
                color: CwcColors.ink,
                fontSize: 18,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
