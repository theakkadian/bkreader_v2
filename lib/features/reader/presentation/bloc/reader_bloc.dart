import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/audio/audio_player_port.dart';
import '../../../scan/domain/entities/book_content.dart';
import '../../../scan/domain/repositories/book_repository.dart';
import '../../domain/entities/reader_session.dart';

part 'reader_event.dart';
part 'reader_state.dart';

class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  ReaderBloc({
    required AudioPlayerPort audioPlayer,
    required BookRepository bookRepository,
  })  : _audio = audioPlayer,
        _bookRepository = bookRepository,
        super(const ReaderInitial()) {
    on<LoadContent>(_onLoadContent);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<ToggleZoom>(_onToggleZoom);
    on<OpenVideo>(_onOpenVideo);
    on<ClearReader>(_onClear);
    on<ShowReaderFailure>(_onShowFailure);
    on<_AudioStateChanged>(_onAudioStateChanged);

    _audioSub = _audio.stateStream.listen((s) {
      add(_AudioStateChanged(s));
    });
  }

  final AudioPlayerPort _audio;
  final BookRepository _bookRepository;
  StreamSubscription<AudioPlaybackState>? _audioSub;
  static const _cancelToken = 'reader';

  /// Set when the current clip reaches the end. A trailing `playing` event
  /// must not put the pause button back until the user starts playback again.
  bool _playbackFinished = false;

  Future<void> _onLoadContent(
    LoadContent event,
    Emitter<ReaderState> emit,
  ) async {
    emit(const ReaderLoading());
    final content = event.content;

    if (!content.isBetkanuProduct) {
      emit(ReaderError(const QrParseFailure(), content: content));
      return;
    }

    final session = ReaderSession(
      contentId: content.textUrl ??
          content.imageUrl ??
          content.audioUrl ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      syriacText: content.syriacText,
      companionText: content.companionText,
      audioUrl: content.audioUrl,
    );

    emit(ReaderReady(content: content, session: session));

    if (content.hasPlayableAudio) {
      add(const PlayAudio());
    }
  }

  Future<void> _onPlayAudio(PlayAudio event, Emitter<ReaderState> emit) async {
    final current = state;
    if (current is! ReaderReady && current is! ReaderPlaying) return;

    final content = switch (current) {
      ReaderReady(:final content) => content,
      ReaderPlaying(:final content) => content,
      _ => null,
    };
    final session = switch (current) {
      ReaderReady(:final session) => session,
      ReaderPlaying(:final session) => session,
      _ => null,
    };
    if (content == null || session == null) return;

    final zoomed = current.isImageZoomed;
    final url = content.audioUrl;
    if (url == null || url.isEmpty) return;

    _playbackFinished = false;
    emit(ReaderPlaying(
      content: content,
      session: session,
      zoomed: zoomed,
    ));

    try {
      // just_audio's play() future completes when playback ends. The finished
      // state comes from the player stream; emitting playing again here would
      // leave the pause button up after the clip is over.
      await _audio.playUrl(url);
    } catch (e, st) {
      AppLogger.e('Play audio failed', e, st);
      if (state is ReaderPlaying || state is ReaderReady) {
        emit(ReaderError(MediaFailure(e.toString()), content: content));
      }
    }
  }

  Future<void> _onPauseAudio(
    PauseAudio event,
    Emitter<ReaderState> emit,
  ) async {
    await _audio.pause();
    final current = state;
    if (current is ReaderPlaying) {
      emit(ReaderReady(
        content: current.content,
        session: current.session,
        zoomed: current.zoomed,
        audioPaused: true,
      ));
    }
  }

  Future<void> _onStopAudio(StopAudio event, Emitter<ReaderState> emit) async {
    await _audio.stop();
    final current = state;
    if (current is ReaderPlaying || current is ReaderReady) {
      final content = switch (current) {
        ReaderPlaying(:final content) => content,
        ReaderReady(:final content) => content,
        _ => null,
      };
      final session = switch (current) {
        ReaderPlaying(:final session) => session,
        ReaderReady(:final session) => session,
        _ => null,
      };
      if (content == null || session == null) return;
      emit(ReaderReady(
        content: content,
        session: session,
        zoomed: current.isImageZoomed,
        audioPaused: true,
      ));
    }
  }

  void _onToggleZoom(ToggleZoom event, Emitter<ReaderState> emit) {
    final current = state;
    if (current is ReaderReady) {
      emit(current.copyWith(zoomed: event.zoomed));
    } else if (current is ReaderPlaying) {
      emit(current.copyWith(zoomed: event.zoomed));
    }
  }

  void _onOpenVideo(OpenVideo event, Emitter<ReaderState> emit) {
    // Video is rendered lazily in UI; reserved for future coordination.
  }

  Future<void> _onClear(ClearReader event, Emitter<ReaderState> emit) async {
    _bookRepository.cancelRequests(_cancelToken);
    _playbackFinished = false;
    await _audio.stop();
    emit(const ReaderInitial());
  }

  void _onShowFailure(
    ShowReaderFailure event,
    Emitter<ReaderState> emit,
  ) {
    if (event.notBetkanuProduct) {
      emit(
        ReaderError(
          event.failure,
          content: const BookContent(isBetkanuProduct: false),
        ),
      );
      return;
    }
    emit(ReaderError(event.failure));
  }

  void _onAudioStateChanged(
    _AudioStateChanged event,
    Emitter<ReaderState> emit,
  ) {
    final current = state;
    if (event.state == AudioPlaybackState.completed) {
      _playbackFinished = true;
      if (current is ReaderPlaying) {
        emit(ReaderReady(
          content: current.content,
          session: current.session,
          zoomed: current.zoomed,
          didCompleteAudio: true,
        ));
      } else if (current is ReaderReady && !current.didCompleteAudio) {
        emit(current.copyWith(didCompleteAudio: true));
      }
    } else if (event.state == AudioPlaybackState.playing) {
      if (_playbackFinished) return;
      if (current is ReaderReady) {
        emit(ReaderPlaying(
          content: current.content,
          session: current.session,
          zoomed: current.zoomed,
        ));
      }
    } else if (event.state == AudioPlaybackState.paused) {
      if (current is ReaderPlaying) {
        emit(ReaderReady(
          content: current.content,
          session: current.session,
          zoomed: current.zoomed,
          audioPaused: true,
        ));
      }
    }
  }

  /// Pause when app backgrounds.
  Future<void> onAppPaused() async {
    await _audio.pause();
  }

  @override
  Future<void> close() async {
    await _audioSub?.cancel();
    _bookRepository.cancelRequests(_cancelToken);
    await _audio.dispose();
    return super.close();
  }
}
