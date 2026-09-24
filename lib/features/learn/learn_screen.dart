import 'package:flutter/material.dart';

import '../../data/content_catalog.dart';
import '../../data/demo_learn.dart';
import '../../theme/cwc_theme.dart';
import 'learn_article_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, this.topics, this.topicsLoader});

  /// Injected topics for tests. When null, loads [kLearnAssetPath].
  final List<DemoLearnTopic>? topics;

  /// Optional override for the asset loader (tests / future hosted JSON).
  final Future<List<DemoLearnTopic>> Function()? topicsLoader;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final Future<List<DemoLearnTopic>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicsFuture = _startLoad();
  }

  Future<List<DemoLearnTopic>> _startLoad() {
    if (widget.topics != null) {
      return Future<List<DemoLearnTopic>>.value(widget.topics!);
    }
    if (widget.topicsLoader != null) {
      return widget.topicsLoader!();
    }
    return loadLearnTopics();
  }

  IconData _iconFor(String label) {
    switch (label) {
      case 'body':
        return Icons.accessibility_new;
      case 'mind':
        return Icons.psychology_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'move':
        return Icons.directions_walk;
      case 'meds':
        return Icons.medication_outlined;
      case 'shield':
        return Icons.health_and_safety_outlined;
      case 'sleep':
        return Icons.bedtime_outlined;
      case 'stress':
        return Icons.self_improvement_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DemoLearnTopic>>(
      future: _topicsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: const [
              Text(
                'Loading topics…',
                style: TextStyle(color: CwcColors.sub, height: 1.35),
              ),
            ],
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: const [
              Text(
                'Learn topics could not load. Try again later.',
                style: TextStyle(color: CwcColors.sub, height: 1.35),
              ),
            ],
          );
        }
        final topics = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Short, plain-language topics from trusted sources.',
              style: TextStyle(color: CwcColors.sub, height: 1.35),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(1) >= 1.3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topics.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: largeText ? 1 : 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: largeText ? 220 : 176,
                  ),
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LearnArticleScreen(topic: topic),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _iconFor(topic.iconLabel),
                                color: CwcColors.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                topic.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  topic.summary,
                                  style: const TextStyle(
                                    color: CwcColors.sub,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Sources are labeled on each article (for example, CDC).',
              style: TextStyle(color: CwcColors.sub, fontSize: 18),
            ),
          ],
        );
      },
    );
  }
}
