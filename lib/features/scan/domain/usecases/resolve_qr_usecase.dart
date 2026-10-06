import '../entities/resolved_target.dart';
import 'normalize_qr_url_usecase.dart';

/// Classifies a raw QR string into youtube | xml | betkanuApi | invalid.
class ResolveQrUseCase {
  ResolveQrUseCase(this._normalize);

  final NormalizeQrUrlUseCase _normalize;

  ResolvedTarget call(String rawQr) {
    final value = _normalize(rawQr);
    final lower = value.toLowerCase();

    if (lower.contains('youtu.be') || lower.contains('youtube')) {
      return YoutubeTarget(value);
    }

    if (lower.contains('.xml')) {
      return XmlTarget(value);
    }

    if (lower.contains('betkanu')) {
      return BetKanuApiTarget(_parseQueryParams(value));
    }

    return const InvalidTarget();
  }

  /// Mirrors the legacy switch on query-pair count (1–4 pairs).
  Map<String, String> _parseQueryParams(String url) {
    final parts = url.split('?');
    if (parts.length < 2) return {};

    final pairs = <String>[];
    for (final segment in parts[1].split('&')) {
      final kv = segment.split('=');
      if (kv.length >= 2) {
        pairs.add(kv[0]);
        pairs.add(kv.sublist(1).join('='));
      }
    }

    final map = <String, String>{};
    final pairCount = pairs.length ~/ 2;
    switch (pairCount) {
      case 1:
        map[pairs[0]] = pairs[1];
      case 2:
        map[pairs[0]] = pairs[1];
        map[pairs[2]] = pairs[3];
      case 3:
        map[pairs[0]] = pairs[1];
        map[pairs[2]] = pairs[3];
        map[pairs[4]] = pairs[5];
      case 4:
        map[pairs[0]] = pairs[1];
        map[pairs[2]] = pairs[3];
        map[pairs[4]] = pairs[5];
        map[pairs[6]] = pairs[7];
      default:
        break;
    }
    return map;
  }
}
