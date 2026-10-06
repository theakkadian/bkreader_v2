import 'package:equatable/equatable.dart';

/// Session snapshot for future progress tracking and auto-read.
class ReaderSession extends Equatable {
  const ReaderSession({
    required this.contentId,
    required this.syriacText,
    this.companionText = '',
    this.audioUrl,
    this.position = Duration.zero,
  });

  final String contentId;
  final String syriacText;
  final String companionText;
  final String? audioUrl;
  final Duration position;

  ReaderSession copyWith({
    String? contentId,
    String? syriacText,
    String? companionText,
    String? audioUrl,
    Duration? position,
  }) {
    return ReaderSession(
      contentId: contentId ?? this.contentId,
      syriacText: syriacText ?? this.syriacText,
      companionText: companionText ?? this.companionText,
      audioUrl: audioUrl ?? this.audioUrl,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props =>
      [contentId, syriacText, companionText, audioUrl, position];
}
