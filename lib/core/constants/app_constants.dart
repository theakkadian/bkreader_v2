/// Application-wide constants for BET KANU Reader.
class AppConstants {
  AppConstants._();

  static const String apiHost = 'www.betkanu.com';
  static const String apiPath = '/api/BKReader';
  static const String fromHeader = 'BETKANU';

  static const String introAudioAsset = 'assets/audios/intro.mp3';
  static const String scanAudioAsset = 'assets/audios/scan.mp3';
  static const String backgroundImage = 'assets/images/background.png';
  static const String logoImage = 'assets/images/BK_Reader_logo.png';
  static const String bottomBarSvg = 'assets/images/bottom_bar.svg';
  static const String placeholderImage = 'assets/images/cooming_soon3.jpg';
  static const String capniLogo = 'assets/images/Capni.png';

  static const String androidAppId = 'com.BETKANU.BK_READER';
  static const String iosBundleId = 'com.BETKANU.BKREADER';
  static const String iosAppId = '1452612542';

  static const String facebookUrl = 'http://facebook.com/BetKanu';
  static const String youtubeChannelUrl = 'https://www.youtube.com/@BETKANU';
  static const String websiteUrl = 'https://www.betkanu.com/home/reader';

  static const String shareMessage =
      'BET KANU Reader App :\n'
      'For Android : '
      'https://play.google.com/store/apps/details?id=com.BETKANU.BK_READER&hl=en&pli=1'
      '\nFor iOS : '
      'https://apps.apple.com/tr/app/bet-kanu-reader/id1452612542';

  /// Max retries for network fetches (API / text).
  static const int maxRetries = 3;

  /// Base backoff between retries.
  static const Duration retryBackoff = Duration(milliseconds: 400);

  /// Ignore duplicate QR detections within this window.
  /// Tuned for snappy retry after failed scans without double-firing.
  static const Duration qrDebounce = Duration(milliseconds: 1000);

  /// Hard timeout per HTTP attempt (API / XML / text).
  static const Duration networkTimeout = Duration(seconds: 12);
}
