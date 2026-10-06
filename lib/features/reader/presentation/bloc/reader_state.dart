part of 'reader_bloc.dart';

sealed class ReaderState extends Equatable {
  const ReaderState();

  BookContent? get contentOrNull => switch (this) {
        ReaderReady(:final content) => content,
        ReaderPlaying(:final content) => content,
        ReaderError(:final content) => content,
        _ => null,
      };

  bool get canPlayAudio {
    final c = contentOrNull;
    return c != null && c.hasPlayableAudio && c.isBetkanuProduct;
  }

  bool get isPlaying => this is ReaderPlaying;

  bool get audioCompleted => switch (this) {
        ReaderReady(:final didCompleteAudio) => didCompleteAudio,
        _ => false,
      };

  bool get isImageZoomed => switch (this) {
        ReaderReady(:final zoomed) => zoomed,
        ReaderPlaying(:final zoomed) => zoomed,
        _ => false,
      };

  @override
  List<Object?> get props => [];
}

class ReaderInitial extends ReaderState {
  const ReaderInitial();
}

class ReaderLoading extends ReaderState {
  const ReaderLoading();
}

class ReaderReady extends ReaderState {
  const ReaderReady({
    required this.content,
    required this.session,
    this.zoomed = false,
    this.audioPaused = false,
    this.didCompleteAudio = false,
  });

  final BookContent content;
  final ReaderSession session;
  final bool zoomed;
  final bool audioPaused;
  final bool didCompleteAudio;

  ReaderReady copyWith({
    BookContent? content,
    ReaderSession? session,
    bool? zoomed,
    bool? audioPaused,
    bool? didCompleteAudio,
  }) {
    return ReaderReady(
      content: content ?? this.content,
      session: session ?? this.session,
      zoomed: zoomed ?? this.zoomed,
      audioPaused: audioPaused ?? this.audioPaused,
      didCompleteAudio: didCompleteAudio ?? this.didCompleteAudio,
    );
  }

  @override
  List<Object?> get props =>
      [content, session, zoomed, audioPaused, didCompleteAudio];
}

class ReaderPlaying extends ReaderState {
  const ReaderPlaying({
    required this.content,
    required this.session,
    this.zoomed = false,
  });

  final BookContent content;
  final ReaderSession session;
  final bool zoomed;

  ReaderPlaying copyWith({
    BookContent? content,
    ReaderSession? session,
    bool? zoomed,
  }) {
    return ReaderPlaying(
      content: content ?? this.content,
      session: session ?? this.session,
      zoomed: zoomed ?? this.zoomed,
    );
  }

  @override
  List<Object?> get props => [content, session, zoomed];
}

class ReaderError extends ReaderState {
  const ReaderError(this.failure, {this.content});

  final Failure failure;
  final BookContent? content;

  @override
  List<Object?> get props => [failure, content];
}
