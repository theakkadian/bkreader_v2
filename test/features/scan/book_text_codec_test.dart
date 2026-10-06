import 'dart:convert';

import 'package:bk_reader_v2/features/scan/data/text/book_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeBookTextBytes', () {
    test('decodes Surayt curriculum UTF-16 LE text as Syriac', () {
      // First line of https://betkanu.com/suraytcurriculum/L1/1.txt
      // FF FE BOM, then UTF-16 LE: ܐܰܪܝܳܐ\r\n
      const bytes = <int>[
        0xFF, 0xFE, //
        0x10, 0x07, 0x30, 0x07, 0x2A, 0x07, 0x1D, 0x07, 0x33, 0x07, 0x10, 0x07,
        0x0D, 0x00, 0x0A, 0x00,
      ];

      expect(decodeBookTextBytes(bytes), 'ܐܰܪܝܳܐ\n');
    });

    test('decodes a full Surayt L1 lesson without mojibake', () {
      const bytes = <int>[
        255, 254, 16, 7, 48, 7, 42, 7, 29, 7, 51, 7, 16, 7, 13, 0, 10, 0, 16,
        7, 48, 7, 42, 7, 29, 7, 51, 7, 16, 7, 32, 0, 26, 7, 48, 7, 32, 7, 29, 7,
        51, 7, 16, 7, 32, 0, 32, 0, 32, 0, 32, 0, 32, 0, 32, 0, 32, 0, 18, 7,
        35, 7, 48, 7, 24, 7, 31, 7, 51, 7, 16, 7, 32, 0, 43, 7, 48, 7, 42, 7,
        29, 7, 51, 7, 16, 7, 13, 0, 10, 0, 18, 7, 26, 7, 48, 7, 29, 7, 32, 7,
        51, 7, 16, 7, 32, 0, 41, 7, 48, 7, 24, 7, 29, 7, 51, 7, 16, 7, 32, 0,
        32, 0, 32, 0, 32, 0, 32, 0, 32, 0, 24, 7, 41, 7, 51, 7, 32, 7, 51, 7,
        16, 7, 32, 0, 37, 7, 48, 7, 32, 7, 29, 7, 51, 7, 16, 7, 13, 0, 10, 0,
      ];

      final text = decodeBookTextBytes(bytes);
      expect(text, contains('ܐܰܪܝܳܐ'));
      expect(text, contains('ܚܰܠܝܳܐ'));
      expect(text, isNot(contains('\uFFFD')));
      expect(RegExp(r'[a-zA-Z]').hasMatch(text), isFalse);
    });

    test('keeps UTF-8 books readable', () {
      final bytes = utf8.encode('Hello world\nܫܠܡܐ');
      expect(decodeBookTextBytes(bytes), 'Hello world\nܫܠܡܐ');
    });

    test('strips a UTF-8 BOM', () {
      final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode('ܫܠܡܐ')];
      expect(decodeBookTextBytes(bytes), 'ܫܠܡܐ');
    });

    test('decodes UTF-16 LE without a BOM', () {
      const bytes = <int>[0x2B, 0x07, 0x21, 0x07, 0x20, 0x00];
      expect(decodeBookTextBytes(bytes), 'ܫܡ ');
    });
  });
}
