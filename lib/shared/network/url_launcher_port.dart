import 'package:url_launcher/url_launcher.dart';

/// Opens external URLs (YouTube) without coupling blocs to url_launcher APIs.
abstract class UrlLauncherPort {
  Future<bool> launch(String url);
}

class UrlLauncherAdapter implements UrlLauncherPort {
  @override
  Future<bool> launch(String url) {
    return launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }
}
