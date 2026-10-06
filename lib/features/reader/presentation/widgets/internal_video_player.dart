import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';

/// Lazily initializes [VideoPlayerController] only while mounted.
class InternalVideoPlayer extends StatefulWidget {
  const InternalVideoPlayer({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<InternalVideoPlayer> createState() => _InternalVideoPlayerState();
}

class _InternalVideoPlayerState extends State<InternalVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _init;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _init = _controller!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _playing = false;
      } else {
        c.play();
        _playing = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.loaderBlue),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final aspect =
            c.value.isInitialized ? c.value.aspectRatio : 16 / 9;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth / aspect,
                  child: FutureBuilder<void>(
                    future: _init,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          c.value.isInitialized) {
                        return AspectRatio(
                          aspectRatio: aspect,
                          child: VideoPlayer(c),
                        );
                      }
                      return SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxWidth / aspect,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.loaderBlue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (c.value.isInitialized)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _playing ? Icons.pause : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggle,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: const SliderThemeData(
                          trackHeight: 2,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 6),
                        ),
                        child: ValueListenableBuilder(
                          valueListenable: c,
                          builder: (context, value, _) {
                            final max =
                                value.duration.inMilliseconds.toDouble();
                            final pos = value.position.inMilliseconds
                                .toDouble()
                                .clamp(0, max > 0 ? max : 0);
                            return Slider(
                              value: max > 0 ? pos.toDouble() : 0,
                              min: 0,
                              max: max > 0 ? max : 1,
                              onChanged: (v) {
                                c.seekTo(Duration(milliseconds: v.toInt()));
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
