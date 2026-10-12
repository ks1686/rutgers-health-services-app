import 'dart:convert';

import 'package:flutter/services.dart';

import 'demo_learn.dart';

const kLearnAssetPath = 'assets/content/learn.json';

List<DemoLearnTopic>? _cachedLearnTopics;

List<DemoLearnTopic> parseLearnTopics(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! List) {
    throw const FormatException('learn.json must be a list');
  }
  return [
    for (final row in decoded)
      if (row is Map) _topicFromRow(row),
  ];
}

DemoLearnTopic _topicFromRow(Map row) {
  return DemoLearnTopic(
    title: row['title'] as String,
    iconLabel: row['iconLabel'] as String,
    summary: row['summary'] as String,
    body: row['body'] as String,
    source: row['source'] as String,
    linkLabel: _optionalString(row['linkLabel']),
    linkUrl: _optionalHttps(row['linkUrl']),
    articlesHeading: _optionalString(row['articlesHeading']),
    articles: _articlesFrom(row['articles']),
  );
}

List<LearnArticle> _articlesFrom(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw const FormatException('articles must be a list');
  }
  return [
    for (final row in raw)
      if (row is Map)
        LearnArticle(
          title: row['title'] as String,
          summary: row['summary'] as String,
          body: row['body'] as String,
          source: row['source'] as String,
          linkLabel: _optionalString(row['linkLabel']),
          linkUrl: _optionalHttps(row['linkUrl']),
        ),
  ];
}

String? _optionalString(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) {
    throw const FormatException('expected a string');
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

String? _optionalHttps(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) {
    throw const FormatException('linkUrl must be a string');
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    throw FormatException('linkUrl must be an https URL');
  }
  return uri.toString();
}

/// Offline-first Learn catalog from the bundled asset.
///
/// Parsed topics are cached after the first successful [rootBundle] read so
/// repeated pumps in widget tests do not re-enter a hanging asset load.
Future<List<DemoLearnTopic>> loadLearnTopics({AssetBundle? bundle}) async {
  if (bundle != null) {
    final raw = await bundle.loadString(kLearnAssetPath);
    return parseLearnTopics(raw);
  }
  final cached = _cachedLearnTopics;
  if (cached != null) {
    return cached;
  }
  final raw = await rootBundle.loadString(kLearnAssetPath);
  return _cachedLearnTopics = parseLearnTopics(raw);
}
