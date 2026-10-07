import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import 'caption_cue.dart';
import 'how_to_catalog.dart';
import 'tutorial_video_cache.dart';

class HowToScreen extends StatefulWidget {
  const HowToScreen({super.key, this.loader});

  final Future<List<HowToTutorial>> Function()? loader;

  @override
  State<HowToScreen> createState() => _HowToScreenState();
}

class _HowToScreenState extends State<HowToScreen> {
  late final Future<List<HowToTutorial>> _future = widget.loader != null
      ? widget.loader!()
      : loadHowToTutorials();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use This App'),
        actions: const [HelpNowButton()],
      ),
      body: FutureBuilder<List<HowToTutorial>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'The how-to steps could not be opened. They are stored on this phone.',
                style: TextStyle(fontSize: 18, height: 1.4),
              ),
            );
          }
          final tutorials = snapshot.data!;
          return ListView(
            key: const ValueKey('how-to-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text(
                'These steps stay on the phone. You can read them with no internet. '
                'Ask a Peer is a separate button on More.',
                style: TextStyle(fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final tutorial in tutorials)
                Card(
                  child: ListTile(
                    minVerticalPadding: 16,
                    title: Text(
                      tutorial.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      tutorial.summary,
                      style: const TextStyle(fontSize: 18, height: 1.35),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HowToDetailScreen(tutorial: tutorial),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class HowToDetailScreen extends StatelessWidget {
  const HowToDetailScreen({
    super.key,
    required this.tutorial,
    this.cache,
    this.captionsLoader,
  });

  final HowToTutorial tutorial;
  final TutorialVideoCache? cache;
  final Future<String> Function(String asset)? captionsLoader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tutorial.title),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            tutorial.summary,
            style: const TextStyle(fontSize: 18, height: 1.4),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < tutorial.steps.length; i++) ...[
            Text(
              'Step ${i + 1}. ${tutorial.steps[i].title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _StepPicture(tutorial.steps[i].picture),
            const SizedBox(height: 8),
            Text(
              tutorial.steps[i].body,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
          _VideoBlock(
            tutorial: tutorial,
            cache: cache,
            captionsLoader: captionsLoader,
          ),
        ],
      ),
    );
  }
}

class _StepPicture extends StatelessWidget {
  const _StepPicture(this.picture);

  final String picture;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step picture. $picture',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CwcColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CwcColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone_android, size: 40, color: CwcColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  picture,
                  style: const TextStyle(fontSize: 18, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoBlock extends StatefulWidget {
  const _VideoBlock({required this.tutorial, this.cache, this.captionsLoader});

  final HowToTutorial tutorial;
  final TutorialVideoCache? cache;
  final Future<String> Function(String asset)? captionsLoader;

  @override
  State<_VideoBlock> createState() => _VideoBlockState();
}

class _VideoBlockState extends State<_VideoBlock> {
  late final Future<String> _captions = widget.captionsLoader != null
      ? widget.captionsLoader!(widget.tutorial.video.captionsAsset)
      : rootBundle.loadString(widget.tutorial.video.captionsAsset);
  String? _status;

  String _videoNote(HowToVideo video) {
    final seconds = video.seconds;
    if (video.downloadUrl == null) {
      return 'About $seconds seconds. This build has the steps and captions. '
          'It does not include a video file to download.';
    }
    return 'About $seconds seconds. Videos do not play by themselves. '
        'A video file downloads only on Wi-Fi, then stays on this phone. '
        'Captions work with no internet.';
  }

  Future<void> _download() async {
    final cache = widget.cache;
    final url = widget.tutorial.video.downloadUrl;
    if (cache == null || url == null) return;
    final result = await cache.prepare(
      id: widget.tutorial.id,
      url: url,
      seconds: widget.tutorial.video.seconds,
    );
    if (!mounted) return;
    setState(() {
      if (result.saved) {
        _status = 'Video saved on this phone for offline playback.';
      } else if (result.needsWifi) {
        _status =
            'Connect to Wi-Fi to download this video. It is not downloaded on mobile data.';
      } else if (result.rejectedBecauseTooLong) {
        _status = 'That video is longer than 90 seconds, so it was not saved.';
      } else {
        _status = 'No video file is available yet.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.tutorial.video;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Short video',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _videoNote(video),
          style: const TextStyle(
            fontSize: 18,
            height: 1.4,
            color: CwcColors.sub,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<String>(
          future: _captions,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Text('Loading captions…');
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Text(
                'Captions could not be opened.',
                style: TextStyle(fontSize: 18),
              );
            }
            final cues = parseWebVtt(snapshot.data!);
            return CaptionPlayer(cues: cues);
          },
        ),
        if (video.downloadUrl != null) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _download,
            child: const Text('Download video on Wi-Fi'),
          ),
        ],
        if (_status != null) ...[
          const SizedBox(height: 8),
          Text(_status!, style: const TextStyle(fontSize: 18, height: 1.4)),
        ],
      ],
    );
  }
}

class CaptionPlayer extends StatefulWidget {
  const CaptionPlayer({super.key, required this.cues});

  final List<CaptionCue> cues;

  @override
  State<CaptionPlayer> createState() => _CaptionPlayerState();
}

class _CaptionPlayerState extends State<CaptionPlayer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    final end = _endOf(widget.cues);
    if (end > Duration.zero) {
      _controller = AnimationController(vsync: this, duration: end);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Duration _endOf(List<CaptionCue> cues) {
    var end = Duration.zero;
    for (final cue in cues) {
      if (cue.end > end) end = cue.end;
    }
    return end;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Text(
        'No captions for this step.',
        style: TextStyle(fontSize: 18),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final position = controller.duration! * controller.value;
        final cue = cueAt(widget.cues, position);
        final playing = controller.isAnimating;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CwcColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CwcColors.line),
              ),
              child: Text(
                cue?.text ??
                    (playing ? '' : 'Captions stay off until you press play.'),
                style: const TextStyle(fontSize: 18, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('caption-play'),
              onPressed: () {
                if (playing) {
                  controller.stop();
                  setState(() {});
                  return;
                }
                controller.forward(from: 0);
              },
              child: Text(playing ? 'Stop' : 'Play captions'),
            ),
          ],
        );
      },
    );
  }
}
