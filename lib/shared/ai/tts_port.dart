/// Port for text-to-speech. Implement with a real engine later.
abstract class TtsPort {
  Future<void> speak(String text, {String? languageCode});
  Future<void> stop();
  Future<void> setRate(double rate);
}

/// No-op TTS until a real Syriac-capable engine is wired.
class FakeTtsPort implements TtsPort {
  @override
  Future<void> speak(String text, {String? languageCode}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setRate(double rate) async {}
}
