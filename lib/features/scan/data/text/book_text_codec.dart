import 'dart:convert';

/// Decodes remote book-text bytes into a Dart string.
///
/// Surayt curriculum files are saved as Windows "Unicode": UTF-16 LE with a
/// BOM. The server returns them as `text/plain` with no charset, so treating
/// every file as UTF-8 turns the Syriac into replacement characters.
String decodeBookTextBytes(List<int> bytes) {
  if (bytes.isEmpty) return '';

  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return _normalize(_decodeUtf16(bytes.sublist(2), littleEndian: true));
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return _normalize(_decodeUtf16(bytes.sublist(2), littleEndian: false));
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return _normalize(utf8.decode(bytes.sublist(3), allowMalformed: true));
  }
  if (_looksLikeUtf16(bytes, littleEndian: true)) {
    return _normalize(_decodeUtf16(bytes, littleEndian: true));
  }
  if (_looksLikeUtf16(bytes, littleEndian: false)) {
    return _normalize(_decodeUtf16(bytes, littleEndian: false));
  }
  return _normalize(utf8.decode(bytes, allowMalformed: true));
}

String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
  final end = bytes.length - (bytes.length.isOdd ? 1 : 0);
  final codes = List<int>.filled(end ~/ 2, 0);
  var n = 0;
  for (var i = 0; i < end; i += 2) {
    final lo = littleEndian ? bytes[i] : bytes[i + 1];
    final hi = littleEndian ? bytes[i + 1] : bytes[i];
    codes[n++] = (hi << 8) | lo;
  }
  return String.fromCharCodes(codes);
}

/// High bytes of 0x00 (ASCII), 0x06 (Arabic), or 0x07 (Syriac) across most
/// pairs means the file is UTF-16 even when the BOM was omitted.
bool _looksLikeUtf16(List<int> bytes, {required bool littleEndian}) {
  if (bytes.length < 4) return false;
  final sample = bytes.length > 80 ? 80 : bytes.length;
  final pairs = sample ~/ 2;
  var hits = 0;
  for (var i = 0; i + 1 < pairs * 2; i += 2) {
    final hi = littleEndian ? bytes[i + 1] : bytes[i];
    if (hi == 0x00 || hi == 0x06 || hi == 0x07) hits++;
  }
  return hits / pairs >= 0.8;
}

String _normalize(String text) {
  var value = text;
  if (value.startsWith('\uFEFF')) {
    value = value.substring(1);
  }
  return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}
