import 'package:flutter/material.dart';

import '../../widgets/help_now_button.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [HelpNowButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          body,
          style: const TextStyle(fontSize: 16, height: 1.45),
        ),
      ),
    );
  }
}
