import 'dart:io';

import 'package:cwc_health_app/features/how_to/caption_cue.dart';
import 'package:cwc_health_app/features/how_to/how_to_catalog.dart';
import 'package:cwc_health_app/features/settings/app_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('text size multiplies the phone setting and defaults to match', () {
    expect(textScaleFactor(TextSizeChoice.system), 1);
    expect(textScaleFactor(TextSizeChoice.large), 1.25);
    expect(textScaleFactor(TextSizeChoice.extraLarge), 1.5);
    expect(textSizeFromStored(null), TextSizeChoice.system);
    final combined = combineTextScaler(
      TextScaler.linear(2),
      TextSizeChoice.large,
    );
    expect(combined.scale(1), 2.5);
  });

  test('blank town preference keeps the Nearby default', () {
    String townFor(Map<String, Object> saved) =>
        AppPreferences(saved).nearbyPlace.town;
    expect(townFor({}), 'New Brunswick');
    expect(townFor({kRememberedTownPref: '  '}), 'New Brunswick');
    expect(townFor({kRememberedTownPref: 'Trenton'}), 'Trenton');
  });

  test('how-to steps are bundled and videos stay within 90 seconds', () {
    final json = File('assets/content/how_to.json').readAsStringSync();
    final tutorials = parseHowToTutorials(json);
    expect(tutorials, isNotEmpty);
    expect(tutorials.map((item) => item.title), contains('Find a pharmacy'));
    expect(tutorials.map((item) => item.title), isNot(contains('Ask a Peer')));
    final addMed = tutorials.firstWhere(
      (item) => item.id == 'add-a-medication',
    );
    expect(addMed.title, 'Add a medication');
    expect(addMed.steps.first.title, 'Open My Health');
    for (final tutorial in tutorials) {
      expect(tutorial.steps, isNotEmpty);
      expect(tutorial.video.seconds, inInclusiveRange(1, 90));
      expect(
        File(tutorial.video.captionsAsset).readAsStringSync(),
        contains('WEBVTT'),
      );
    }
  });

  test('captions parse and follow the play position', () {
    const raw = '''
WEBVTT

00:00.000 --> 00:02.000
First line.

00:02.000 --> 00:04.000
Second line.
''';
    final cues = parseWebVtt(raw);
    expect(cues, hasLength(2));
    expect(cueAt(cues, const Duration(milliseconds: 500))?.text, 'First line.');
    expect(cueAt(cues, const Duration(seconds: 2))?.text, 'Second line.');
    expect(cueAt(cues, const Duration(seconds: 4)), isNull);
  });
}
