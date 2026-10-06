import 'package:bk_reader_v2/features/scan/domain/entities/resolved_target.dart';
import 'package:bk_reader_v2/features/scan/domain/usecases/normalize_qr_url_usecase.dart';
import 'package:bk_reader_v2/features/scan/domain/usecases/resolve_qr_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ResolveQrUseCase resolve;

  setUp(() {
    resolve = ResolveQrUseCase(const NormalizeQrUrlUseCase());
  });

  group('ResolveQrUseCase', () {
    test('detects YouTube short links', () {
      final target = resolve('https://youtu.be/abc123');
      expect(target, isA<YoutubeTarget>());
      expect((target as YoutubeTarget).url, 'https://youtu.be/abc123');
    });

    test('detects YouTube full links', () {
      final target = resolve('https://www.youtube.com/watch?v=abc');
      expect(target, isA<YoutubeTarget>());
    });

    test('detects XML bundles and normalizes typos', () {
      final target = resolve(
        'https://cdn.example/betkanu/books/kidssongsbookk/song.xml',
      );
      expect(target, isA<XmlTarget>());
      final xml = target as XmlTarget;
      expect(xml.normalizedUrl, contains('betkanu.com'));
      expect(xml.normalizedUrl, contains('kidssongsbook'));
      expect(xml.normalizedUrl, isNot(contains('kidssongsbookk')));
    });

    test('parses BetKanu API query params (2 pairs)', () {
      final target = resolve(
        'https://www.betkanu.com/reader?book=1&page=2',
      );
      expect(target, isA<BetKanuApiTarget>());
      final api = target as BetKanuApiTarget;
      expect(api.queryParams, {'book': '1', 'page': '2'});
    });

    test('parses up to 4 query pairs', () {
      final target = resolve(
        'https://www.betkanu.com/r?a=1&b=2&c=3&d=4',
      );
      final api = target as BetKanuApiTarget;
      expect(api.queryParams.length, 4);
      expect(api.queryParams['d'], '4');
    });

    test('rejects non-BetKanu QR', () {
      final target = resolve('https://example.com/other');
      expect(target, isA<InvalidTarget>());
    });
  });
}
