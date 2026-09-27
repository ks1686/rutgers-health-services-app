import 'dart:io';

import 'package:cwc_health_app/features/how_to/caption_cue.dart';
import 'package:cwc_health_app/features/how_to/how_to_catalog.dart';
import 'package:cwc_health_app/features/how_to/tutorial_video_cache.dart';
import 'package:cwc_health_app/features/settings/app_preferences.dart';
import 'package:cwc_health_app/features/wellness/wellness_goals.dart';
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
    expect(nearbyTownFromPreference(null), 'New Brunswick');
    expect(nearbyTownFromPreference('  '), 'New Brunswick');
    expect(nearbyTownFromPreference('Trenton'), 'Trenton');
  });

  test('wellness nudges stay off until each one is turned on', () {
    const goals = WellnessGoals();
    expect(goals.water, isFalse);
    expect(goals.breath, isFalse);
    expect(goals.steps, isFalse);
    expect(goals.steadySleep, isFalse);
    expect(goals.nudgeWhenClose, isFalse);
    expect(goals.showCloseNudge, isFalse);

    final close = goals.copyWith(
      steps: true,
      nudgeWhenClose: true,
      stepGoal: 4000,
      stepsToday: 3200,
    );
    expect(close.showCloseNudge, isTrue);
    expect(close.copyWith(stepsToday: 4000).showCloseNudge, isFalse);
    expect(close.copyWith(steps: false).showCloseNudge, isFalse);
  });

  test('wellness goals round-trip in the preference store', () async {
    final memory = MemoryPreferenceStore();
    final store = WellnessGoalsStore(memory);
    store.load();
    expect(store.goals.water, isFalse);
    await store.update(store.goals.copyWith(water: true, breath: false));
    final again = WellnessGoalsStore(memory)..load();
    expect(again.goals.water, isTrue);
    expect(again.goals.breath, isFalse);
    expect(again.goals.steps, isFalse);
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
      expect(tutorial.video.downloadUrl, isNull);
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

  test(
    'video download waits for Wi-Fi and then plays from the saved file',
    () async {
      final files = MemoryVideoFileStore();
      final cache = TutorialVideoCache(
        network: FixedNetworkKind(NetworkKind.cellular),
        store: files,
        fetch: (_) async => [1, 2, 3],
      );
      final blocked = await cache.prepare(
        id: 'find-a-pharmacy',
        url: Uri.parse('https://example.test/how-to.mp4'),
        seconds: 45,
      );
      expect(blocked.needsWifi, isTrue);
      expect(blocked.saved, isFalse);

      final wifi = TutorialVideoCache(
        network: FixedNetworkKind(NetworkKind.wifi),
        store: files,
        fetch: (_) async => [1, 2, 3],
      );
      final saved = await wifi.prepare(
        id: 'find-a-pharmacy',
        url: Uri.parse('https://example.test/how-to.mp4'),
        seconds: 45,
      );
      expect(saved.saved, isTrue);
      expect(saved.path, 'memory://find-a-pharmacy');

      final offline = TutorialVideoCache(
        network: FixedNetworkKind(NetworkKind.offline),
        store: files,
        fetch: (_) async => throw StateError('should not download again'),
      );
      final replay = await offline.prepare(
        id: 'find-a-pharmacy',
        url: Uri.parse('https://example.test/how-to.mp4'),
        seconds: 45,
      );
      expect(replay.saved, isTrue);
      expect(replay.needsWifi, isFalse);

      final tooLong = await wifi.prepare(
        id: 'too-long',
        url: Uri.parse('https://example.test/long.mp4'),
        seconds: 91,
      );
      expect(tooLong.rejectedBecauseTooLong, isTrue);
      expect(tooLong.saved, isFalse);
    },
  );
}
