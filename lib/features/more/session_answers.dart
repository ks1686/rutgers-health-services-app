import 'dart:convert';

/// Answers from the co-design session questions. On this phone only.
class SessionAnswers {
  const SessionAnswers({
    this.nearby,
    this.helpNow,
    this.moreList,
    this.scarlet,
    this.note = '',
  });

  /// `yes` or `no`. Null means not answered yet.
  final String? nearby;
  final String? helpNow;
  final String? moreList;

  /// `supportive` or `alarming`.
  final String? scarlet;

  final String note;

  static const maxNoteLength = 240;

  SessionAnswers copyWith({
    String? nearby,
    String? helpNow,
    String? moreList,
    String? scarlet,
    String? note,
    bool clearNearby = false,
    bool clearHelpNow = false,
    bool clearMoreList = false,
    bool clearScarlet = false,
  }) {
    return SessionAnswers(
      nearby: clearNearby ? null : (nearby ?? this.nearby),
      helpNow: clearHelpNow ? null : (helpNow ?? this.helpNow),
      moreList: clearMoreList ? null : (moreList ?? this.moreList),
      scarlet: clearScarlet ? null : (scarlet ?? this.scarlet),
      note: note ?? this.note,
    );
  }

  bool get isEmpty =>
      nearby == null &&
      helpNow == null &&
      moreList == null &&
      scarlet == null &&
      note.trim().isEmpty;
}

const sessionYes = 'yes';
const sessionNo = 'no';
const sessionSupportive = 'supportive';
const sessionAlarming = 'alarming';

String sessionAnswersToStored(SessionAnswers answers) {
  final note = answers.note.trim();
  final clipped = note.length > SessionAnswers.maxNoteLength
      ? note.substring(0, SessionAnswers.maxNoteLength)
      : note;
  return jsonEncode({
    'nearby': answers.nearby,
    'helpNow': answers.helpNow,
    'moreList': answers.moreList,
    'scarlet': answers.scarlet,
    'note': clipped,
  });
}

SessionAnswers sessionAnswersFromStored(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return const SessionAnswers();
  final Object? decoded;
  try {
    decoded = jsonDecode(trimmed);
  } on FormatException {
    return const SessionAnswers();
  }
  if (decoded is! Map) return const SessionAnswers();
  return SessionAnswers(
    nearby: _yesNo(decoded['nearby']),
    helpNow: _yesNo(decoded['helpNow']),
    moreList: _yesNo(decoded['moreList']),
    scarlet: _scarlet(decoded['scarlet']),
    note: _note(decoded['note']),
  );
}

String? _yesNo(Object? value) {
  if (value == sessionYes || value == sessionNo) return value as String;
  return null;
}

String? _scarlet(Object? value) {
  if (value == sessionSupportive || value == sessionAlarming) {
    return value as String;
  }
  return null;
}

String _note(Object? value) {
  final text = value is String ? value.trim() : '';
  if (text.length <= SessionAnswers.maxNoteLength) return text;
  return text.substring(0, SessionAnswers.maxNoteLength);
}
