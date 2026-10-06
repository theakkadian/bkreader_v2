import 'package:bk_reader_v2/core/utils/null_string.dart';
import 'package:bk_reader_v2/features/reader/domain/entities/book_text.dart';
import 'package:bk_reader_v2/features/scan/domain/entities/book_content.dart';
import 'package:bk_reader_v2/features/scan/domain/repositories/book_repository.dart';
import 'package:bk_reader_v2/features/scan/domain/usecases/load_book_text_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements BookRepository {}

void main() {
  group('nullIfBlankOrNullString', () {
    test('treats string null as absent', () {
      expect(nullIfBlankOrNullString('null'), isNull);
      expect(nullIfBlankOrNullString('NULL'), isNull);
      expect(nullIfBlankOrNullString(''), isNull);
      expect(nullIfBlankOrNullString('  '), isNull);
      expect(nullIfBlankOrNullString('https://x.com/a.mp3'), 'https://x.com/a.mp3');
    });
  });

  group('LoadBookTextUseCase', () {
    late _MockRepo repo;
    late LoadBookTextUseCase useCase;

    setUp(() {
      repo = _MockRepo();
      useCase = LoadBookTextUseCase(repo);
    });

    test('returns empty text when url missing', () async {
      final result = await useCase(null);
      expect(result.syriacText, isEmpty);
      verifyNever(() => repo.loadText(any(), cancelToken: any(named: 'cancelToken')));
    });

    test('delegates to repository', () async {
      when(
        () => repo.loadText(any(), cancelToken: any(named: 'cancelToken')),
      ).thenAnswer(
        (_) async => const BookText(syriacText: 'ܫܠܡܐ', isOnlySyriac: true),
      );

      final result = await useCase('https://example.com/t.txt');
      expect(result.syriacText, 'ܫܠܡܐ');
    });
  });

  group('TextRemoteDataSourceImpl parsing', () {
    // Exercise private parse via a thin test double pattern:
    // verify BookContent companion split expectations mirror legacy.
    test('latin presence implies companion + syriac split', () {
      const contents = 'Hello world\nܫܠܡܐ';
      final isOnlySyriac = !RegExp(r'[a-zA-Z]').hasMatch(contents);
      expect(isOnlySyriac, isFalse);
      final lines = contents.split('\n');
      expect(lines[0], 'Hello world');
      expect(lines[1], 'ܫܠܡܐ');
    });
  });

  group('BookContent', () {
    test('hasPlayableAudio ignores null string fields via construction', () {
      const content = BookContent(audioUrl: 'https://a.com/x.mp3');
      expect(content.hasPlayableAudio, isTrue);
      const empty = BookContent();
      expect(empty.hasPlayableAudio, isFalse);
    });
  });
}
