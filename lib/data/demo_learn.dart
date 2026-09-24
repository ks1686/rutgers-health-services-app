/// Learn topic model. Runtime content comes from `assets/content/learn.json`
/// via [loadLearnTopics] / [parseLearnTopics].
class DemoLearnTopic {
  const DemoLearnTopic({
    required this.title,
    required this.iconLabel,
    required this.summary,
    required this.body,
    required this.source,
  });

  final String title;
  final String iconLabel;
  final String summary;
  final String body;
  final String source;
}
