import 'package:cwc_health_app/features/more/session_answers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session answers round-trip and drop unknown values', () {
    const answers = SessionAnswers(
      nearby: sessionYes,
      helpNow: sessionNo,
      moreList: sessionYes,
      scarlet: sessionAlarming,
      note: '  The list is easy to see.  ',
    );
    final stored = sessionAnswersToStored(answers);
    final parsed = sessionAnswersFromStored(stored);
    expect(parsed.nearby, sessionYes);
    expect(parsed.helpNow, sessionNo);
    expect(parsed.moreList, sessionYes);
    expect(parsed.scarlet, sessionAlarming);
    expect(parsed.note, 'The list is easy to see.');
  });

  test('bad or empty session storage is an empty sheet', () {
    expect(sessionAnswersFromStored(null).isEmpty, isTrue);
    expect(sessionAnswersFromStored('').isEmpty, isTrue);
    expect(sessionAnswersFromStored('{').isEmpty, isTrue);
    expect(sessionAnswersFromStored('[]').isEmpty, isTrue);
    expect(
      sessionAnswersFromStored(
        '{"nearby":"maybe","scarlet":"red","note":"ok"}',
      ).nearby,
      isNull,
    );
    expect(sessionAnswersFromStored('{"note":"ok"}').note, 'ok');
  });

  test('a long note is clipped', () {
    final note = 'a' * (SessionAnswers.maxNoteLength + 20);
    final parsed = sessionAnswersFromStored(
      sessionAnswersToStored(SessionAnswers(note: note)),
    );
    expect(parsed.note.length, SessionAnswers.maxNoteLength);
  });
}
