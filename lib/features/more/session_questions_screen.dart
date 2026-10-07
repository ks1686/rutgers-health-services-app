import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import '../settings/app_preferences.dart';
import 'session_answers.dart';

/// Co-design questions from the README, answered on the phone.
class SessionQuestionsScreen extends StatefulWidget {
  const SessionQuestionsScreen({super.key});

  @override
  State<SessionQuestionsScreen> createState() => _SessionQuestionsScreenState();
}

class _SessionQuestionsScreenState extends State<SessionQuestionsScreen> {
  final TextEditingController _note = TextEditingController();
  var _noteLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_noteLoaded) return;
    _noteLoaded = true;
    final prefs = AppPreferencesScope.maybeOf(context);
    _note.text = prefs?.sessionAnswers.note ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(SessionAnswers answers) async {
    final prefs = AppPreferencesScope.maybeOf(context);
    if (prefs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save on this phone.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await prefs.setSessionAnswers(answers);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferencesScope.maybeOf(context);
    final answers = prefs?.sessionAnswers ?? const SessionAnswers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session questions'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text(
            'These answers stay on this phone. They are not sent anywhere. '
            'Erase my information deletes them.',
            style: TextStyle(color: CwcColors.sub, fontSize: 18, height: 1.4),
          ),
          const SizedBox(height: 20),
          _YesNoQuestion(
            question: 'Can you find Nearby vs My Health?',
            value: answers.nearby,
            yesKey: const ValueKey('session-nearby-yes'),
            noKey: const ValueKey('session-nearby-no'),
            onChanged: (value) => _save(answers.copyWith(nearby: value)),
          ),
          _YesNoQuestion(
            question: 'Is Help Now always one tap away?',
            value: answers.helpNow,
            yesKey: const ValueKey('session-help-yes'),
            noKey: const ValueKey('session-help-no'),
            onChanged: (value) => _save(answers.copyWith(helpNow: value)),
          ),
          _YesNoQuestion(
            question: 'Does More feel like a visible list (not a hidden menu)?',
            value: answers.moreList,
            yesKey: const ValueKey('session-more-yes'),
            noKey: const ValueKey('session-more-no'),
            onChanged: (value) => _save(answers.copyWith(moreList: value)),
          ),
          _ChoiceQuestion(
            question: 'Does scarlet branding feel supportive or alarming?',
            leftLabel: 'Supportive',
            leftValue: sessionSupportive,
            rightLabel: 'Alarming',
            rightValue: sessionAlarming,
            value: answers.scarlet,
            leftKey: const ValueKey('session-scarlet-supportive'),
            rightKey: const ValueKey('session-scarlet-alarming'),
            onChanged: (value) => _save(answers.copyWith(scarlet: value)),
          ),
          const Text(
            'Anything else you want us to know?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('session-note'),
            controller: _note,
            maxLength: SessionAnswers.maxNoteLength,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Optional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              key: const ValueKey('session-note-save'),
              onPressed: () => _save(answers.copyWith(note: _note.text)),
              child: const Text('Save note'),
            ),
          ),
        ],
      ),
    );
  }
}

class _YesNoQuestion extends StatelessWidget {
  const _YesNoQuestion({
    required this.question,
    required this.value,
    required this.yesKey,
    required this.noKey,
    required this.onChanged,
  });

  final String question;
  final String? value;
  final Key yesKey;
  final Key noKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ChoiceQuestion(
      question: question,
      leftLabel: 'Yes',
      leftValue: sessionYes,
      rightLabel: 'No',
      rightValue: sessionNo,
      value: value,
      leftKey: yesKey,
      rightKey: noKey,
      onChanged: onChanged,
    );
  }
}

class _ChoiceQuestion extends StatelessWidget {
  const _ChoiceQuestion({
    required this.question,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.value,
    required this.leftKey,
    required this.rightKey,
    required this.onChanged,
  });

  final String question;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final String? value;
  final Key leftKey;
  final Key rightKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ChoiceButton(
                  buttonKey: leftKey,
                  label: leftLabel,
                  selected: value == leftValue,
                  onPressed: () => onChanged(leftValue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceButton(
                  buttonKey: rightKey,
                  label: rightLabel,
                  selected: value == rightValue,
                  onPressed: () => onChanged(rightValue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (selected) ...[
          const Icon(Icons.check, size: 20),
          const SizedBox(width: 6),
        ],
        Flexible(child: Text(label, style: const TextStyle(fontSize: 18))),
      ],
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    if (selected) {
      return FilledButton(
        key: buttonKey,
        style: style,
        onPressed: onPressed,
        child: child,
      );
    }
    return OutlinedButton(
      key: buttonKey,
      style: style,
      onPressed: onPressed,
      child: child,
    );
  }
}
