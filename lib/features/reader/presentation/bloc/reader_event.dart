part of 'reader_bloc.dart';

sealed class ReaderEvent extends Equatable {
  const ReaderEvent();

  @override
  List<Object?> get props => [];
}

class LoadContent extends ReaderEvent {
  const LoadContent(this.content);
  final BookContent content;

  @override
  List<Object?> get props => [content];
}

class PlayAudio extends ReaderEvent {
  const PlayAudio();
}

class PauseAudio extends ReaderEvent {
  const PauseAudio();
}

class StopAudio extends ReaderEvent {
  const StopAudio();
}

class ToggleZoom extends ReaderEvent {
  const ToggleZoom(this.zoomed);
  final bool zoomed;

  @override
  List<Object?> get props => [zoomed];
}

class OpenVideo extends ReaderEvent {
  const OpenVideo();
}

class ClearReader extends ReaderEvent {
  const ClearReader();
}

class ShowReaderFailure extends ReaderEvent {
  const ShowReaderFailure(this.failure, {this.notBetkanuProduct = false});
  final Failure failure;
  final bool notBetkanuProduct;

  @override
  List<Object?> get props => [failure, notBetkanuProduct];
}

class _AudioStateChanged extends ReaderEvent {
  const _AudioStateChanged(this.state);
  final AudioPlaybackState state;

  @override
  List<Object?> get props => [state];
}
