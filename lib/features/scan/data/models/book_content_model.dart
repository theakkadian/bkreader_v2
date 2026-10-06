import '../../../../core/utils/null_string.dart';
import '../../domain/entities/book_content.dart';

class BookContentModel {
  const BookContentModel({
    this.imageUrl,
    this.textUrl,
    this.textLanguage,
    this.audioUrl,
    this.videoUrl,
  });

  final String? imageUrl;
  final String? textUrl;
  final String? textLanguage;
  final String? audioUrl;
  final String? videoUrl;

  factory BookContentModel.fromJson(Map<String, dynamic> json) {
    return BookContentModel(
      imageUrl: nullIfBlankOrNullString(json['ImageURL']),
      textUrl: _textUrlFrom(json['TextURL']),
      textLanguage: nullIfBlankOrNullString(json['TextLanguage']),
      audioUrl: nullIfBlankOrNullString(json['AudioURL']),
      videoUrl: nullIfBlankOrNullString(json['VideoURL']),
    );
  }

  factory BookContentModel.fromXmlBundle(Map<String, dynamic> bundle) {
    return BookContentModel(
      imageUrl: nullIfBlankOrNullString(bundle['ImageURL']),
      textUrl: _textUrlFrom(bundle['TextURL']),
      textLanguage: nullIfBlankOrNullString(bundle['TextLanguage']),
      audioUrl: nullIfBlankOrNullString(bundle['AudioURL']),
      videoUrl: nullIfBlankOrNullString(bundle['VideoURL']),
    );
  }

  static String? _textUrlFrom(dynamic raw) {
    final url = nullIfBlankOrNullString(raw);
    if (url == null || containsHtml(url)) return null;
    return url;
  }

  BookContent toEntity() {
    final image = imageUrl != null ? sanitizeMediaUrl(imageUrl!) : null;
    final video = videoUrl != null ? sanitizeMediaUrl(videoUrl!) : null;
    final isSvg = image?.toLowerCase().contains('.svg') ?? false;
    final isInternalVideo = video?.toLowerCase().contains('.mp4') ?? false;

    return BookContent(
      imageUrl: image,
      textUrl: textUrl,
      textLanguage: textLanguage,
      audioUrl: audioUrl != null ? sanitizeMediaUrl(audioUrl!) : null,
      videoUrl: video,
      isSvg: isSvg,
      isInternalVideo: isInternalVideo,
      isBetkanuProduct: true,
    );
  }
}
