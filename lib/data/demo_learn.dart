/// One short Learn article. Runtime content comes from `assets/content/learn.json`.
class LearnArticle {
  const LearnArticle({
    required this.title,
    required this.summary,
    required this.body,
    required this.source,
    this.linkLabel,
    this.linkUrl,
  });

  final String title;
  final String summary;
  final String body;
  final String source;
  final String? linkLabel;
  final String? linkUrl;

  /// Https link-out, or null when missing or unsafe.
  Uri? get link => learnHttpsUri(linkUrl);

  DemoLearnTopic toTopic() {
    return DemoLearnTopic(
      title: title,
      iconLabel: 'article',
      summary: summary,
      body: body,
      source: source,
      linkLabel: linkLabel,
      linkUrl: linkUrl,
    );
  }
}

/// Learn area. Runtime content comes from `assets/content/learn.json`
/// via [loadLearnTopics] / [parseLearnTopics].
class DemoLearnTopic {
  const DemoLearnTopic({
    required this.title,
    required this.iconLabel,
    required this.summary,
    required this.body,
    required this.source,
    this.linkLabel,
    this.linkUrl,
    this.articlesHeading,
    this.articles = const [],
  });

  final String title;
  final String iconLabel;
  final String summary;
  final String body;
  final String source;
  final String? linkLabel;
  final String? linkUrl;

  /// Section title for [articles], when this area holds more than one note.
  final String? articlesHeading;
  final List<LearnArticle> articles;

  /// Https link-out, or null when missing or unsafe.
  Uri? get link => learnHttpsUri(linkUrl);
}

/// Returns an https URI, or null if [raw] is missing or not https.
Uri? learnHttpsUri(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}
