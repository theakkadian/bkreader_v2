import 'package:bk_reader_v2/features/reader/domain/entities/book_text.dart';
import 'package:bk_reader_v2/features/reader/domain/entities/reader_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderSession', () {
    test('equality and copyWith', () {
      const base = ReaderSession(
        contentId: 'c1',
        syriacText: 'ܐ',
        companionText: 'a',
        audioUrl: 'https://x.com/a.mp3',
      );
      final updated = base.copyWith(
        position: const Duration(seconds: 12),
        companionText: 'b',
      );

      expect(updated.contentId, 'c1');
      expect(updated.syriacText, 'ܐ');
      expect(updated.companionText, 'b');
      expect(updated.audioUrl, 'https://x.com/a.mp3');
      expect(updated.position, const Duration(seconds: 12));
      expect(updated, isNot(equals(base)));
      expect(
        updated.copyWith(position: Duration.zero, companionText: 'a'),
        base,
      );
    });
  });

  group('BookText', () {
    test('equality uses all fields', () {
      const a = BookText(syriacText: 'ܐ', companionText: 'x', isOnlySyriac: false);
      const b = BookText(syriacText: 'ܐ', companionText: 'x', isOnlySyriac: false);
      const c = BookText(syriacText: 'ܐ');

      expect(a, b);
      expect(a, isNot(equals(c)));
      expect(c.isOnlySyriac, isTrue);
      expect(c.companionText, '');
    });
  });
}
