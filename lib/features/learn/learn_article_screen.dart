import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/demo_learn.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import '../../widgets/link_launcher.dart';

class LearnArticleScreen extends StatelessWidget {
  const LearnArticleScreen({super.key, required this.topic, this.launcher});

  final DemoLearnTopic topic;
  final LinkLauncher? launcher;

  Future<void> _openLink(BuildContext context, Uri uri) async {
    final open = launcher ?? _launchExternal;
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

  Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final link = topic.link;
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            topic.summary,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (topic.body.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(topic.body, style: const TextStyle(fontSize: 18, height: 1.5)),
          ],
          if (topic.source.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CwcColors.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'From: ${topic.source}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (link != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _openLink(context, link),
              child: Text(
                topic.linkLabel ?? 'Read more',
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
                            topic: article.toTopic(),
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
