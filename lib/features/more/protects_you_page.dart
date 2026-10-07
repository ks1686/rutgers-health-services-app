import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';

/// Plain-language privacy page (PRIV-3). Study-build wording, not a CAB sign-off.
const kProtectsYouParagraphs = <String>[
  'Appointments, medicines, providers, papers, reminders, your PIN, people '
      'you save under Ask a Peer, and session question answers stay on this '
      'phone. They are not uploaded. There is no cloud account for them.',
  'The phone stores them with its built-in secure storage. This app has no '
      'ads and does not track how you use it. You do not need an account.',
  'Nearby can use your location one time if you tap that choice. It sorts '
      'the list and then drops the location. It does not save a trail of '
      'where you go. You can pick a town instead. Saying no does not block '
      'Nearby, Learn, or Help Now.',
  'An optional PIN can hide My Health. It never blocks Nearby, Learn, or '
      'Help Now.',
  'Erase my information deletes those personal items from this phone. You '
      'cannot undo that.',
  'The community can still change this wording.',
];

class ProtectsYouPage extends StatelessWidget {
  const ProtectsYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How This App Protects You'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final paragraph in kProtectsYouParagraphs) ...[
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
