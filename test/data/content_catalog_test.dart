import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/data/content_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('learn.json parses six sourced topics', () {
    final json = File('assets/content/learn.json').readAsStringSync();
    final topics = parseLearnTopics(json);
    expect(topics, hasLength(6));
    expect(topics.first.source, isNotEmpty);
    expect(topics.first.title, 'Physical Health');
  });

  test('loadLearnTopics reads the bundled asset', () async {
    final topics = await loadLearnTopics();
    expect(topics, hasLength(6));
    expect(topics.map((t) => t.title), contains('Mental Health'));
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
