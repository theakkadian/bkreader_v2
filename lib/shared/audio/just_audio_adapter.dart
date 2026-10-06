import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../core/utils/app_logger.dart';
import 'audio_player_port.dart';

class JustAudioAdapter implements AudioPlayerPort {
  JustAudioAdapter() {
    _subscription = _player.playerStateStream.listen(_onPlayerState);
  }

  final AudioPlayer _player = AudioPlayer();
  final _controller = StreamController<AudioPlaybackState>.broadcast();
  StreamSubscription<PlayerState>? _subscription;
  int _playbackEpoch = 0;
  bool _resetScheduled = false;

  void _onPlayerState(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _controller.add(AudioPlaybackState.completed);
      // playing stays true after the clip ends until pause/stop. Reset so the
      // next play starts at the beginning and the stream does not keep
      // reporting playback.
      if (!_resetScheduled) {
        _resetScheduled = true;
        unawaited(_resetToStart(_playbackEpoch));
      }
      return;
    }

    _resetScheduled = false;

    if (state.playing) {
      _controller.add(AudioPlaybackState.playing);
    } else if (state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering) {
      _controller.add(AudioPlaybackState.loading);
    } else {
      _controller.add(AudioPlaybackState.paused);
    }
  }

  Future<void> _resetToStart(int epoch) async {
    if (epoch != _playbackEpoch) return;
    try {
      await _player.pause();
      if (epoch != _playbackEpoch) return;
      await _player.seek(Duration.zero);
    } catch (e, st) {
      AppLogger.e('Reset after playback failed', e, st);
    }
  }

  @override
  Stream<AudioPlaybackState> get stateStream => _controller.stream;

  @override
  Future<void> playAsset(String assetPath) async {
    final epoch = ++_playbackEpoch;
    _resetScheduled = false;
    try {
      await _player.setAudioSource(AudioSource.asset(assetPath));
      if (epoch != _playbackEpoch) return;
      await _player.play();
    } catch (e, st) {
      AppLogger.e('playAsset failed', e, st);
    }
  }

  @override
  Future<void> playUrl(String url) async {
    final epoch = ++_playbackEpoch;
    _resetScheduled = false;
    try {
      await _player.setUrl(url);
      if (epoch != _playbackEpoch) return;
      await _player.play();
    } catch (e, st) {
      AppLogger.e('playUrl failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
    await _player.dispose();
  }
}
