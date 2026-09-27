import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/data/content_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('learn.json parses sourced topics with Sleep on its own', () {
    final json = File('assets/content/learn.json').readAsStringSync();
    final topics = parseLearnTopics(json);
    expect(topics, hasLength(6));
    expect(topics.first.source, isNotEmpty);
    expect(topics.first.title, 'Physical Health');
    expect(
      topics.map((t) => t.title),
      containsAll([
        'Physical Health',
        'Mental Health',
        'Nutrition',
        'Exercise',
        'Preventive Care',
        'Sleep',
      ]),
    );
    expect(topics.map((t) => t.title), isNot(contains('Medications')));
    expect(topics.map((t) => t.title), isNot(contains('Stress')));
    expect(topics.map((t) => t.title), isNot(contains('Stress management')));

    final physical = topics.firstWhere((t) => t.title == 'Physical Health');
    expect(physical.body.toLowerCase(), isNot(contains('sleep')));
    expect(physical.body, contains('My Health'));
    expect(physical.body.toLowerCase(), contains('medicines'));
    expect(physical.articlesHeading, 'Stress management');
    expect(physical.articles, hasLength(2));
    expect(
      physical.articles.map((a) => a.title),
      containsAll([
        'Everyday ways to ease stress',
        'When stress feels like too much',
      ]),
    );
    expect(
      physical.articles.map((a) => a.body).join(' ').toLowerCase(),
      contains('do not have to track'),
    );
    for (final article in physical.articles) {
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
  });

  test('loadLearnTopics reads the bundled asset', () async {
    final topics = await loadLearnTopics();
    expect(topics, hasLength(6));
    expect(topics.map((t) => t.title), contains('Mental Health'));
    expect(topics.map((t) => t.title), contains('Sleep'));
    expect(topics.map((t) => t.title), isNot(contains('Medications')));
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

  test('help_now.json parses demo actions with 911 first', () {
    final json = File('assets/content/help_now.json').readAsStringSync();
    final actions = parseHelpNowActions(json);
    expect(actions, hasLength(7));
    expect(actions.first.label, '911 Emergency');
    expect(
      actions.map((a) => a.label),
      containsAll(['ReachNJ', 'NJ Self-Help Group Clearinghouse']),
    );
  });

  test('health.json parses sample wallet and meds', () {
    final json = File('assets/content/health.json').readAsStringSync();
    final health = parseHealthCatalog(json);
    expect(health.appointments, hasLength(2));
    expect(health.medications.first.name, 'Metformin');
    expect(health.walletConditions, contains('Diabetes'));
  });

  test('resources.json parses New Brunswick demo rows', () {
    final json = File('assets/content/resources.json').readAsStringSync();
    final catalog = parseResourceCatalog(json);
    expect(catalog.town, 'New Brunswick');
    expect(catalog.resources, hasLength(5));
    expect(catalog.resources.first.name, 'Main Street Pharmacy');
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
