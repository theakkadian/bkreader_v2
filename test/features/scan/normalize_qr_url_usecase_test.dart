import 'package:bk_reader_v2/features/scan/domain/usecases/normalize_qr_url_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normalize = NormalizeQrUrlUseCase();

  group('NormalizeQrUrlUseCase', () {
    test('adds .com when missing from betkanu path', () {
      final result = normalize(
        'https://cdn.example/betkanu/books/kidssongsbook/page.xml',
      );
      expect(result, contains('betkanu.com'));
      expect(result, isNot(contains('/betkanu/')));
    });

    test('fixes kidssongsbookk typo', () {
      final result = normalize(
        'https://www.betkanu.com/books/kidssongsbookk/page.xml',
      );
      expect(result, contains('kidssongsbook'));
      expect(result, isNot(contains('kidssongsbookk')));
    });

    test('maps zmryothedzaaorebook to kidssongsbook', () {
      final result = normalize(
        'https://www.betkanu.com/books/zmryothedzaaorebook/page.xml',
      );
      expect(result, contains('kidssongsbook'));
    });

    test('strips spaces and encoded CRLF', () {
      final result = normalize('https://example.com/a%0D%0A.xml ');
      expect(result, 'https://example.com/a.xml');
    });

    test('strips newlines and tabs inside printed QR payloads', () {
      final result = normalize('https://www.betkanu.com/r?\nbook=1\t');
      expect(result, 'https://www.betkanu.com/r?book=1');
    });
  });
}
