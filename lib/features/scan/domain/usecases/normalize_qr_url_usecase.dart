/// Isolates ALL historical URL / typo quirks from printed BET KANU books.
///
/// Printed QR codes occasionally contain typos or missing `.com`. Keep these
/// replacements in one place so real books continue to work.
class NormalizeQrUrlUseCase {
  const NormalizeQrUrlUseCase();

  String call(String raw) {
    // Trim + collapse all whitespace/newlines printed QRs sometimes inject.
    var url = raw.trim().replaceAll(RegExp(r'\s+'), '');

    // Domain without .com: /betkanu/ → /betkanu.com/
    if (!url.toLowerCase().contains('.com')) {
      url = url.replaceAll('/betkanu/', '/betkanu.com/');
    }

    // Known typos in legacy printed song books.
    url = url
        .replaceAll('kidssongsbookk', 'kidssongsbook')
        .replaceAll('zmryothedzaaorebook', 'kidssongsbook');

    // Strip accidental CRLF encodings that appear in some TextURL/ImageURL values.
    url = url.replaceAll('%0D%0A', '').replaceAll('%0A', '').replaceAll('%0D', '');

    return url;
  }
}
