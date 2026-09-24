import 'dart:convert';

import 'package:flutter/services.dart';

const kHowToAssetPath = 'assets/content/how_to.json';

class HowToStep {
  const HowToStep({
    required this.title,
    required this.body,
    required this.picture,
  });

  final String title;
  final String body;
  final String picture;

  factory HowToStep.fromJson(Map<String, dynamic> json) {
    return HowToStep(
      title: json['title'] as String,
      body: json['body'] as String,
      picture: json['picture'] as String,
    );
  }
}

class HowToVideo {
  const HowToVideo({
    required this.seconds,
    required this.captionsAsset,
    this.downloadUrl,
  });

  final int seconds;
  final String captionsAsset;
  final Uri? downloadUrl;

  factory HowToVideo.fromJson(Map<String, dynamic> json, String tutorialId) {
    final seconds = json['seconds'] as int;
    if (seconds > 90) {
      throw FormatException('Video for $tutorialId is longer than 90 seconds');
    }
    final rawUrl = json['downloadUrl'] as String?;
    return HowToVideo(
      seconds: seconds,
      captionsAsset: json['captionsAsset'] as String,
      downloadUrl: rawUrl == null || rawUrl.isEmpty ? null : Uri.parse(rawUrl),
    );
  }
}

class HowToTutorial {
  const HowToTutorial({
    required this.id,
    required this.title,
    required this.summary,
    required this.steps,
    required this.video,
  });

  final String id;
  final String title;
  final String summary;
  final List<HowToStep> steps;
  final HowToVideo video;

  factory HowToTutorial.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final steps = json['steps'];
    if (steps is! List || steps.isEmpty) {
      throw FormatException('Tutorial $id needs steps');
    }
    final video = json['video'];
    if (video is! Map) {
      throw FormatException('Tutorial $id needs a video block');
    }
    return HowToTutorial(
      id: id,
      title: json['title'] as String,
      summary: json['summary'] as String,
      steps: [
        for (final row in steps)
          if (row is Map) HowToStep.fromJson(Map<String, dynamic>.from(row)),
      ],
      video: HowToVideo.fromJson(Map<String, dynamic>.from(video), id),
    );
  }
}

List<HowToTutorial> parseHowToTutorials(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map) {
    throw const FormatException('how_to.json must be an object');
  }
  final rows = decoded['tutorials'];
  if (rows is! List || rows.isEmpty) {
    throw const FormatException('how_to.json tutorials must be a list');
  }
  return [
    for (final row in rows)
      if (row is Map) HowToTutorial.fromJson(Map<String, dynamic>.from(row)),
  ];
}

Future<List<HowToTutorial>> loadHowToTutorials({AssetBundle? bundle}) async {
  final source = bundle ?? rootBundle;
  final raw = await source.loadString(kHowToAssetPath);
  return parseHowToTutorials(raw);
}
