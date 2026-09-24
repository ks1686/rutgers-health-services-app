class CaptionCue {
  const CaptionCue({
    required this.start,
    required this.end,
    required this.text,
  });

  final Duration start;
  final Duration end;
  final String text;
}

List<CaptionCue> parseWebVtt(String raw) {
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  final cues = <CaptionCue>[];
  var index = 0;
  if (lines.isNotEmpty && lines.first.trim().startsWith('WEBVTT')) {
    index = 1;
  }
  while (index < lines.length) {
    final line = lines[index].trim();
    if (!line.contains('-->')) {
      index++;
      continue;
    }
    final parts = line.split('-->');
    final start = _parseTimestamp(parts[0].trim());
    final end = _parseTimestamp(parts[1].trim().split(' ').first);
    index++;
    final text = <String>[];
    while (index < lines.length && lines[index].trim().isNotEmpty) {
      text.add(lines[index].trim());
      index++;
    }
    if (text.isNotEmpty) {
      cues.add(CaptionCue(start: start, end: end, text: text.join(' ')));
    }
  }
  return cues;
}

CaptionCue? cueAt(List<CaptionCue> cues, Duration position) {
  for (final cue in cues) {
    if (position >= cue.start && position < cue.end) return cue;
  }
  return null;
}

Duration _parseTimestamp(String raw) {
  final pieces = raw.split(':');
  if (pieces.length == 2) {
    final seconds = double.parse(pieces[1]);
    return Duration(
      minutes: int.parse(pieces[0]),
      milliseconds: (seconds * 1000).round(),
    );
  }
  if (pieces.length == 3) {
    final seconds = double.parse(pieces[2]);
    return Duration(
      hours: int.parse(pieces[0]),
      minutes: int.parse(pieces[1]),
      milliseconds: (seconds * 1000).round(),
    );
  }
  throw FormatException('Bad caption time: $raw');
}
