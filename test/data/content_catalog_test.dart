import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/data/content_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'learn.json parses sourced topics with Sleep and Stress on their own',
    () {
      final json = File('assets/content/learn.json').readAsStringSync();
      final topics = parseLearnTopics(json);
      expect(topics, hasLength(6));
      expect(topics.first.source, isNotEmpty);
      expect(topics.first.title, 'Physical Health');
      expect(topics.map((t) => t.title), [
        'Physical Health',
        'Mental Health',
        'Stress Management',
        'Nutrition',
        'Preventive Care',
        'Sleep',
      ]);
      expect(topics.map((t) => t.title), isNot(contains('Medications')));
      expect(topics.map((t) => t.title), isNot(contains('Exercise')));
      expect(topics.map((t) => t.title), isNot(contains('Stress')));
      expect(topics.map((t) => t.title), isNot(contains('Stress management')));

      final physical = topics.firstWhere((t) => t.title == 'Physical Health');
      expect(physical.body.toLowerCase(), isNot(contains('sleep')));
      expect(physical.body, contains('My Health'));
      expect(physical.body.toLowerCase(), contains('medicines'));
      expect(physical.articlesHeading, isNull);
      expect(physical.articles.map((a) => a.title), [
        'A checkup when you feel okay',
        'Moving a little each day',
      ]);

      final padded = [
        physical,
        topics.firstWhere((t) => t.title == 'Mental Health'),
        topics.firstWhere((t) => t.title == 'Nutrition'),
        topics.firstWhere((t) => t.title == 'Preventive Care'),
      ];
      for (final topic in padded) {
        expect(topic.articles, hasLength(2), reason: topic.title);
        for (final article in topic.articles) {
          expect(article.source, isNotEmpty, reason: article.title);
          expect(article.link, isNotNull, reason: article.title);
          expect(article.link!.scheme, 'https');
        }
      }
      expect(
        topics
            .firstWhere((t) => t.title == 'Mental Health')
            .articles
            .map((a) => a.link!.host),
        ['www.nimh.nih.gov', 'medlineplus.gov'],
      );

      final stress = topics.firstWhere((t) => t.title == 'Stress Management');
      expect(stress.articlesHeading, isNull);
      expect(stress.articles, hasLength(2));
      expect(
        stress.articles.map((a) => a.title),
        containsAll([
          'Everyday ways to ease stress',
          'When stress feels like too much',
        ]),
      );
      expect(
        stress.articles.map((a) => a.body).join(' ').toLowerCase(),
        contains('do not have to track'),
      );
      for (final article in stress.articles) {
        expect(article.source, isNotEmpty);
        expect(article.link, isNotNull);
        expect(article.link!.scheme, 'https');
      }

      final sleep = topics.firstWhere((t) => t.title == 'Sleep');
      expect(sleep.articles.map((a) => a.title), [
        'Everyday sleep tips',
        'Sleep apnea',
      ]);
      expect(sleep.articles.map((a) => a.link!.host), [
        'medlineplus.gov',
        'www.nhlbi.nih.gov',
      ]);
    },
  );

  test('loadLearnTopics reads the bundled asset', () async {
    final topics = await loadLearnTopics();
    expect(topics, hasLength(6));
    expect(topics.map((t) => t.title), contains('Mental Health'));
    expect(topics.map((t) => t.title), contains('Sleep'));
    expect(topics.map((t) => t.title), contains('Stress Management'));
    expect(topics.map((t) => t.title), isNot(contains('Medications')));
    expect(topics.map((t) => t.title), isNot(contains('Exercise')));
  });

  test('loadLearnTopics uses an injected AssetBundle', () async {
    final bundle = _StringBundle('''
[
  {
    "title": "Sleep",
    "iconLabel": "sleep",
    "summary": "Rest matters.",
    "body": "Try a regular bedtime when you can.",
    "source": "CDC"
  }
]
''');
    final topics = await loadLearnTopics(bundle: bundle);
    expect(topics, hasLength(1));
    expect(topics.single.title, 'Sleep');
  });

  test('learn linkUrl must be https', () {
    expect(
      () => parseLearnTopics('''
[
  {
    "title": "Sleep",
    "iconLabel": "sleep",
    "summary": "Rest matters.",
    "body": "Try a regular bedtime when you can.",
    "source": "CDC",
    "linkUrl": "http://example.com/sleep"
  }
]
'''),
      throwsFormatException,
    );
  });

  test('no bundled JSON ships placeholder phone numbers', () {
    for (final entity in Directory('assets/content').listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      expect(
        entity.readAsStringSync(),
        isNot(contains('555-')),
        reason: '${entity.path} still holds a 555 placeholder number',
      );
    }
  });

  test('no bundled JSON carries placeholder content markers', () {
    const markers = ['Main Street Pharmacy', 'Dr. Rivera', 'Metformin'];
    for (final entity in Directory('assets/content').listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final body = entity.readAsStringSync();
      for (final marker in markers) {
        expect(
          body,
          isNot(contains(marker)),
          reason: '${entity.path} still ships sample content ($marker)',
        );
      }
    }
  });

  test('no widget test reaches the live Nearby network', () {
    // Nearby has no static fallback any more, so a widget test that forgets a
    // stub would quietly hit Nominatim/Overpass and make the suite depend on
    // the internet.
    for (final entity in Directory('test').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('_test.dart')) continue;
      if (entity.path.contains(RegExp(r'/support/|/nearby/'))) continue;
      final body = entity.readAsStringSync();
      if (!body.contains('CwcApp(')) continue;
      expect(
        body,
        contains('nearbyRepository:'),
        reason:
            '${entity.path} builds CwcApp without a nearbyRepository stub, so '
            'the Nearby tab would hit the network during tests',
      );
    }
  });
}

class _StringBundle extends AssetBundle {
  _StringBundle(this._json);

  final String _json;

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError('load not used; loadString is overridden');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _json;

  @override
  void evict(String key) {}
}
