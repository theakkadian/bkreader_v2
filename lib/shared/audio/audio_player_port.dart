/// Abstraction over audio playback so blocs stay free of just_audio.
abstract class AudioPlayerPort {
  Stream<AudioPlaybackState> get stateStream;

  Future<void> playAsset(String assetPath);
  Future<void> playUrl(String url);
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

enum AudioPlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
}
