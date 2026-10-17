import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/demo_learn.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import '../../widgets/link_launcher.dart';

/// One Learn note: title, summary, body, source, and an optional link.
class LearnArticleScreen extends StatelessWidget {
  const LearnArticleScreen({super.key, required this.article, this.launcher});

  final LearnArticle article;
  final LinkLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _noteChildren(context, article, launcher),
      ),
    );
  }
}

/// A Learn area page: its own note, then a list of further notes.
class LearnTopicScreen extends StatelessWidget {
  const LearnTopicScreen({super.key, required this.topic, this.launcher});

  final LearnTopic topic;
  final LinkLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._noteChildren(context, topic.note, launcher),
          if (topic.articles.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              topic.articlesHeading ?? 'More to read',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            for (final article in topic.articles)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LearnArticleScreen(
                            article: article,
                            launcher: launcher,
                          ),
                        ),
                      );
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              article.summary,
                              style: const TextStyle(
                                color: CwcColors.sub,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

List<Widget> _noteChildren(
  BuildContext context,
  LearnArticle note,
  LinkLauncher? launcher,
) {
  final link = note.link;
  return [
    Text(
      note.summary,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    ),
    if (note.body.trim().isNotEmpty) ...[
      const SizedBox(height: 16),
      Text(note.body, style: const TextStyle(fontSize: 18, height: 1.5)),
    ],
    if (note.source.trim().isNotEmpty) ...[
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CwcColors.primaryTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'From: ${note.source}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
    if (link != null) ...[
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () => _openLink(context, link, launcher),
        child: Text(note.linkLabel ?? 'Read more', textAlign: TextAlign.center),
      ),
    ],
  ];
}

Future<void> _openLink(
  BuildContext context,
  Uri uri,
  LinkLauncher? launcher,
) async {
  final open =
      launcher ??
      (Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
  final opened = await open(uri);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open that page.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
