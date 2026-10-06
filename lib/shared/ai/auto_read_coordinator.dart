import '../../features/reader/domain/entities/reader_session.dart';
import 'tts_port.dart';

/// Stub coordinator for future auto-read (TTS + audio position).
///
/// Blocs can depend on this port without knowing about a concrete TTS engine.
class AutoReadCoordinator {
  AutoReadCoordinator(this._tts);

  final TtsPort _tts;

  Future<void> start(ReaderSession session, {bool preferCompanion = false}) async {
    final text =
        preferCompanion && session.companionText.isNotEmpty
            ? session.companionText
            : session.syriacText;
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
