/// DRAFT wording. Needs Karim and CAB sign-off before it is final.
library;

import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';

/// Draft agreement. Items 7 and 8 are the liability lines and need review.
const kUsingThisAppParagraphs = <String>[
  'This app is a tool to help you keep track of your health information and '
      'find help. It is not a doctor, nurse, or counselor.',
  'It does not give medical advice, a diagnosis, or treatment. Always talk '
      'with your doctor or primary care provider about your health and before '
      'you change any medicine.',
  'In an emergency, call 911. If you are in crisis, call or text 988. Do not '
      'wait for this app.',
  'Phone numbers, places, hours, and articles can change or be wrong. Check '
      'with the place or person before you rely on them. Places listed under '
      'Nearby may not take your insurance or walk-ins.',
  'You decide what you save. Your information stays on this phone. If you '
      'lose the phone, delete the app, or erase your information, it may be '
      'gone for good. Keep copies of important papers.',
  'You choose who you call and when. The app only opens your phone\'s dialer; '
      'you place the call yourself.',
  'You are responsible for the steps you take to get help. The people who '
      'made this app cannot be responsible for choices made using it.',
  'By using this app you agree to use it this way. You can read this again '
      'any time in More.',
];

class UsingThisAppPage extends StatelessWidget {
  const UsingThisAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Using this app'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final paragraph in kUsingThisAppParagraphs) ...[
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
