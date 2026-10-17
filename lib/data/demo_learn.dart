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
}

/// Learn area: a grid tile with its own [note] and any further notes.
/// Runtime content comes from `assets/content/learn.json` via
/// [loadLearnTopics] / [parseLearnTopics].
class LearnTopic {
  const LearnTopic({
    required this.iconLabel,
    required this.note,
    this.articlesHeading,
    this.articles = const [],
  });

  final String iconLabel;

  /// The area's own text, shown first on its page.
  final LearnArticle note;

  /// Section title for [articles], when this area holds more than one note.
  final String? articlesHeading;
  final List<LearnArticle> articles;

  String get title => note.title;
  String get summary => note.summary;
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
