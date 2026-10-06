/// Treats API/XML string "null", empty, and whitespace as absent.
String? nullIfBlankOrNullString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  return s;
}

/// Strip trailing CRLF that sometimes appears in ImageURL fields.
String sanitizeMediaUrl(String url) {
  var cleaned = url.replaceAll('%0D%0A', '');
  if (cleaned.contains('\r\n')) {
    cleaned = cleaned.replaceAll('\r\n', '');
  }
  return cleaned.trim();
}

bool containsHtml(String? text) {
  if (text == null) return false;
  return text.toLowerCase().contains('html');
}
