import 'package:flutter/material.dart';

import '../../data/demo_learn.dart';
import '../../theme/cwc_theme.dart';
import 'learn_article_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

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
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          'Short, plain-language topics from trusted sources.',
          style: TextStyle(color: CwcColors.sub, height: 1.35),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: demoLearnTopics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final topic = demoLearnTopics[index];
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
                      Icon(_iconFor(topic.iconLabel), color: CwcColors.primary),
                      const Spacer(),
                      Text(
                        topic.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic.summary,
                        style: const TextStyle(
                          color: CwcColors.sub,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Sources are labeled on each article (for example, CDC).',
          style: TextStyle(color: CwcColors.sub, fontSize: 13),
        ),
      ],
    );
  }
}
