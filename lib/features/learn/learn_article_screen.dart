import 'package:flutter/material.dart';

import '../../data/demo_learn.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';

class LearnArticleScreen extends StatelessWidget {
  const LearnArticleScreen({super.key, required this.topic});

  final DemoLearnTopic topic;

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
          Text(
            topic.summary,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Text(topic.body, style: const TextStyle(fontSize: 16, height: 1.5)),
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
      ),
    );
  }
}
