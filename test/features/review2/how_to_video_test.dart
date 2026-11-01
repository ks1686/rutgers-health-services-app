import 'package:cwc_health_app/features/how_to/how_to_catalog.dart';
import 'package:cwc_health_app/features/how_to/how_to_screen.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'a downloadUrl in the catalog never shows a download button that does '
    'nothing',
    (tester) async {
      final tutorial = HowToTutorial.fromJson({
        'id': 'find-a-pharmacy',
        'title': 'Find a pharmacy',
        'summary': 'Summary.',
        'steps': [
          {'title': 'Open Nearby', 'body': 'Body.', 'picture': 'Picture.'},
        ],
        'video': {
          'seconds': 45,
          'captionsAsset': 'assets/content/captions/find-a-pharmacy.vtt',
          'downloadUrl': 'https://example.test/how-to.mp4',
        },
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildCwcTheme(),
          home: HowToDetailScreen(
            tutorial: tutorial,
            captionsLoader: (_) async => 'WEBVTT\n',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Short video'), 200);
      await tester.pumpAndSettle();

      expect(find.text('Download video on Wi-Fi'), findsNothing);
      expect(find.textContaining('does not include a video file'), findsOne);
    },
  );
}
