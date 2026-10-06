/// Future AI assistant capabilities — interfaces only.
abstract class AiAssistantPort {
  Future<String> explain(String text);
  Future<String> transliterate(String syriacText);
  Future<List<String>> quiz(String text, {int questionCount = 3});
}

/// No-op AI assistant stub.
class FakeAiAssistantPort implements AiAssistantPort {
  @override
  Future<String> explain(String text) async => '';

  @override
  Future<String> transliterate(String syriacText) async => '';

  @override
  Future<List<String>> quiz(String text, {int questionCount = 3}) async => [];
}
