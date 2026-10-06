import 'package:equatable/equatable.dart';

/// Outcome of classifying a raw QR string before fetching content.
sealed class ResolvedTarget extends Equatable {
  const ResolvedTarget();
}

/// Open externally via url_launcher.
class YoutubeTarget extends ResolvedTarget {
  const YoutubeTarget(this.url);
  final String url;

  @override
  List<Object?> get props => [url];
}

/// Legacy XML BKRBundle download.
class XmlTarget extends ResolvedTarget {
  const XmlTarget(this.normalizedUrl);
  final String normalizedUrl;

  @override
  List<Object?> get props => [normalizedUrl];
}

/// BetKanu API with query parameters.
class BetKanuApiTarget extends ResolvedTarget {
  const BetKanuApiTarget(this.queryParams);
  final Map<String, String> queryParams;

  @override
  List<Object?> get props => [queryParams];
}

/// Not a BETKANU product QR.
class InvalidTarget extends ResolvedTarget {
  const InvalidTarget();

  @override
  List<Object?> get props => [];
}
