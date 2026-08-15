import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/data/content_catalog.dart';

void main() {
  test('learn.json parses six sourced topics', () {
    final json = File('assets/content/learn.json').readAsStringSync();
    final topics = parseLearnTopics(json);
    expect(topics, hasLength(6));
    expect(topics.first.source, isNotEmpty);
    expect(topics.first.title, 'Physical Health');
  });

  test('help_now.json parses five demo actions', () {
    final json = File('assets/content/help_now.json').readAsStringSync();
    final actions = parseHelpNowActions(json);
    expect(actions, hasLength(5));
    expect(actions.first.label, contains('988'));
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
