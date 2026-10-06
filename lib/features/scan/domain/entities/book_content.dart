import 'package:equatable/equatable.dart';

/// Typed scanned book content shown in the reader.
class BookContent extends Equatable {
  const BookContent({
    this.imageUrl,
    this.textUrl,
    this.textLanguage,
    this.audioUrl,
    this.videoUrl,
    this.syriacText = '',
    this.companionText = '',
    this.isOnlySyriac = true,
    this.isSvg = false,
    this.isInternalVideo = false,
    this.isYoutube = false,
    this.isBetkanuProduct = true,
  });

  final String? imageUrl;
  final String? textUrl;
  final String? textLanguage;
  final String? audioUrl;
  final String? videoUrl;
  final String syriacText;
  final String companionText;
  final bool isOnlySyriac;
  final bool isSvg;
  final bool isInternalVideo;
  final bool isYoutube;
  final bool isBetkanuProduct;

  bool get hasPlayableAudio =>
      audioUrl != null && audioUrl!.isNotEmpty;

  BookContent copyWith({
    String? imageUrl,
    String? textUrl,
    String? textLanguage,
    String? audioUrl,
    String? videoUrl,
    String? syriacText,
    String? companionText,
    bool? isOnlySyriac,
    bool? isSvg,
    bool? isInternalVideo,
    bool? isYoutube,
    bool? isBetkanuProduct,
  }) {
    return BookContent(
      imageUrl: imageUrl ?? this.imageUrl,
      textUrl: textUrl ?? this.textUrl,
      textLanguage: textLanguage ?? this.textLanguage,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      syriacText: syriacText ?? this.syriacText,
      companionText: companionText ?? this.companionText,
      isOnlySyriac: isOnlySyriac ?? this.isOnlySyriac,
      isSvg: isSvg ?? this.isSvg,
      isInternalVideo: isInternalVideo ?? this.isInternalVideo,
      isYoutube: isYoutube ?? this.isYoutube,
      isBetkanuProduct: isBetkanuProduct ?? this.isBetkanuProduct,
    );
  }

  @override
  List<Object?> get props => [
        imageUrl,
        textUrl,
        textLanguage,
        audioUrl,
        videoUrl,
        syriacText,
        companionText,
        isOnlySyriac,
        isSvg,
        isInternalVideo,
        isYoutube,
        isBetkanuProduct,
      ];
}
