import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bk_reader_v2/core/error/failures.dart';
import 'package:bk_reader_v2/features/reader/domain/entities/reader_session.dart';
import 'package:bk_reader_v2/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:bk_reader_v2/features/scan/domain/entities/book_content.dart';
import 'package:bk_reader_v2/features/scan/domain/repositories/book_repository.dart';
import 'package:bk_reader_v2/shared/audio/audio_player_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements BookRepository {}

class _FakeAudio implements AudioPlayerPort {
  final _controller = StreamController<AudioPlaybackState>.broadcast();
  final List<String> playUrls = [];
  int pauseCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  bool playUrlThrows = false;

  /// Mirrors just_audio, whose play() future completes when playback ends.
  bool completeBeforeReturn = false;

  @override
  Stream<AudioPlaybackState> get stateStream => _controller.stream;

  void emitState(AudioPlaybackState state) => _controller.add(state);

  @override
  Future<void> playAsset(String assetPath) async {}

  @override
  Future<void> playUrl(String url) async {
    playUrls.add(url);
    if (playUrlThrows) throw Exception('playback failed');
    if (completeBeforeReturn) {
      _controller.add(AudioPlaybackState.completed);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

BookContent _sampleContent({
  bool withAudio = false,
  bool isBetkanu = true,
  String? textUrl = 'https://x.com/t.txt',
}) {
  return BookContent(
    imageUrl: 'https://x.com/a.png',
    textUrl: textUrl,
    audioUrl: withAudio ? 'https://x.com/a.mp3' : null,
    syriacText: 'ܫܠܡܐ',
    companionText: 'hello',
    isBetkanuProduct: isBetkanu,
  );
}

void main() {
  late _MockRepo repo;
  late _FakeAudio audio;
  late ReaderBloc bloc;

  setUp(() {
    repo = _MockRepo();
    audio = _FakeAudio();
    when(() => repo.cancelRequests(any())).thenReturn(null);
    bloc = ReaderBloc(audioPlayer: audio, bookRepository: repo);
  });

  tearDown(() async {
    await bloc.close();
  });

  blocTest<ReaderBloc, ReaderState>(
    'LoadContent without audio → Loading then Ready',
    build: () => bloc,
    act: (b) => b.add(LoadContent(_sampleContent())),
    expect: () => [
      const ReaderLoading(),
      isA<ReaderReady>()
          .having((s) => s.content.syriacText, 'syriac', 'ܫܠܡܐ')
          .having((s) => s.session.contentId, 'id', 'https://x.com/t.txt')
          .having((s) => s.zoomed, 'zoomed', isFalse),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'LoadContent with playable audio auto-plays',
    build: () => bloc,
    act: (b) => b.add(LoadContent(_sampleContent(withAudio: true))),
    expect: () => [
      const ReaderLoading(),
      isA<ReaderReady>(),
      isA<ReaderPlaying>().having(
        (s) => s.content.audioUrl,
        'audio',
        'https://x.com/a.mp3',
      ),
    ],
    verify: (_) {
      expect(audio.playUrls, ['https://x.com/a.mp3']);
    },
  );

  blocTest<ReaderBloc, ReaderState>(
    'non-BetKanu product → ReaderError with QrParseFailure',
    build: () => bloc,
    act: (b) => b.add(LoadContent(_sampleContent(isBetkanu: false))),
    expect: () => [
      const ReaderLoading(),
      isA<ReaderError>()
          .having((s) => s.failure, 'failure', isA<QrParseFailure>())
          .having((s) => s.content?.isBetkanuProduct, 'betkanu', isFalse),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'PlayAudio / PauseAudio / StopAudio round-trip',
    build: () => bloc,
    seed: () => ReaderReady(
      content: _sampleContent(withAudio: true),
      session: const ReaderSession(
        contentId: 'id',
        syriacText: 'ܫܠܡܐ',
        audioUrl: 'https://x.com/a.mp3',
      ),
    ),
    act: (b) async {
      b.add(const PlayAudio());
      await Future<void>.delayed(Duration.zero);
      b.add(const PauseAudio());
      await Future<void>.delayed(Duration.zero);
      b.add(const PlayAudio());
      await Future<void>.delayed(Duration.zero);
      b.add(const StopAudio());
    },
    expect: () => [
      isA<ReaderPlaying>(),
      isA<ReaderReady>().having((s) => s.audioPaused, 'paused', isTrue),
      isA<ReaderPlaying>(),
      isA<ReaderReady>().having((s) => s.audioPaused, 'paused', isTrue),
    ],
    verify: (_) {
      expect(audio.pauseCalls, 1);
      expect(audio.stopCalls, 1);
      expect(audio.playUrls.length, 2);
    },
  );

  blocTest<ReaderBloc, ReaderState>(
    'PlayAudio failure → MediaFailure',
    build: () {
      audio.playUrlThrows = true;
      return bloc;
    },
    seed: () => ReaderReady(
      content: _sampleContent(withAudio: true),
      session: const ReaderSession(
        contentId: 'id',
        syriacText: 'ܫܠܡܐ',
        audioUrl: 'https://x.com/a.mp3',
      ),
    ),
    act: (b) => b.add(const PlayAudio()),
    expect: () => [
      isA<ReaderPlaying>(),
      isA<ReaderError>().having(
        (s) => s.failure,
        'failure',
        isA<MediaFailure>(),
      ),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'auto-play completion restores play button after play() resolves',
    build: () {
      audio.completeBeforeReturn = true;
      return bloc;
    },
    act: (b) => b.add(LoadContent(_sampleContent(withAudio: true))),
    expect: () => [
      const ReaderLoading(),
      isA<ReaderReady>().having(
        (s) => s.didCompleteAudio,
        'completed',
        isFalse,
      ),
      isA<ReaderPlaying>(),
      isA<ReaderReady>().having(
        (s) => s.didCompleteAudio,
        'completed',
        isTrue,
      ),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'playing event after completion does not restore pause',
    build: () => bloc,
    seed: () => ReaderPlaying(
      content: _sampleContent(withAudio: true),
      session: const ReaderSession(
        contentId: 'id',
        syriacText: 'x',
        audioUrl: 'https://x.com/a.mp3',
      ),
    ),
    act: (b) async {
      audio.emitState(AudioPlaybackState.completed);
      await Future<void>.delayed(Duration.zero);
      audio.emitState(AudioPlaybackState.playing);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      isA<ReaderReady>().having(
        (s) => s.didCompleteAudio,
        'completed',
        isTrue,
      ),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'ToggleZoom updates Ready and Playing',
    build: () => bloc,
    seed: () => ReaderReady(
      content: _sampleContent(),
      session: const ReaderSession(contentId: 'id', syriacText: 'x'),
    ),
    act: (b) async {
      b.add(const ToggleZoom(true));
      await Future<void>.delayed(Duration.zero);
      // Switch to playing via audio stream, then toggle again.
      audio.emitState(AudioPlaybackState.playing);
      await Future<void>.delayed(Duration.zero);
      b.add(const ToggleZoom(false));
    },
    expect: () => [
      isA<ReaderReady>().having((s) => s.zoomed, 'zoomed', isTrue),
      isA<ReaderPlaying>().having((s) => s.zoomed, 'zoomed', isTrue),
      isA<ReaderPlaying>().having((s) => s.zoomed, 'zoomed', isFalse),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'audio completed → Ready with didCompleteAudio',
    build: () => bloc,
    seed: () => ReaderPlaying(
      content: _sampleContent(withAudio: true),
      session: const ReaderSession(
        contentId: 'id',
        syriacText: 'x',
        audioUrl: 'https://x.com/a.mp3',
      ),
    ),
    act: (b) => audio.emitState(AudioPlaybackState.completed),
    expect: () => [
      isA<ReaderReady>().having(
        (s) => s.didCompleteAudio,
        'completed',
        isTrue,
      ),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'audio paused stream → Ready with audioPaused',
    build: () => bloc,
    seed: () => ReaderPlaying(
      content: _sampleContent(withAudio: true),
      session: const ReaderSession(
        contentId: 'id',
        syriacText: 'x',
        audioUrl: 'https://x.com/a.mp3',
      ),
    ),
    act: (b) => audio.emitState(AudioPlaybackState.paused),
    expect: () => [
      isA<ReaderReady>().having((s) => s.audioPaused, 'paused', isTrue),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'ClearReader stops audio, cancels HTTP, returns to initial',
    build: () => bloc,
    seed: () => ReaderReady(
      content: _sampleContent(),
      session: const ReaderSession(contentId: 'id', syriacText: 'x'),
    ),
    act: (b) => b.add(const ClearReader()),
    expect: () => [const ReaderInitial()],
    verify: (_) {
      expect(audio.stopCalls, greaterThanOrEqualTo(1));
      verify(() => repo.cancelRequests('reader'))
          .called(greaterThanOrEqualTo(1));
    },
  );

  blocTest<ReaderBloc, ReaderState>(
    'ShowReaderFailure emits ReaderError',
    build: () => bloc,
    act: (b) => b.add(const ShowReaderFailure(ApiFailure())),
    expect: () => [
      isA<ReaderError>().having(
        (s) => s.failure,
        'failure',
        isA<ApiFailure>(),
      ),
    ],
  );

  blocTest<ReaderBloc, ReaderState>(
    'ShowReaderFailure notBetkanuProduct attaches stub content',
    build: () => bloc,
    act: (b) => b.add(
      const ShowReaderFailure(QrParseFailure(), notBetkanuProduct: true),
    ),
    expect: () => [
      isA<ReaderError>()
          .having((s) => s.failure, 'failure', isA<QrParseFailure>())
          .having((s) => s.content?.isBetkanuProduct, 'betkanu', isFalse),
    ],
  );

  test('onAppPaused pauses audio player', () async {
    await bloc.onAppPaused();
    expect(audio.pauseCalls, 1);
  });

  test('session contentId falls back to imageUrl then audioUrl', () async {
    final imageAudio = _FakeAudio();
    final imageOnly = ReaderBloc(
      audioPlayer: imageAudio,
      bookRepository: repo,
    );
    imageOnly.add(
      LoadContent(
        const BookContent(
          imageUrl: 'https://x.com/img.png',
          syriacText: 'x',
        ),
      ),
    );
    await expectLater(
      imageOnly.stream,
      emitsInOrder([
        const ReaderLoading(),
        isA<ReaderReady>().having(
          (s) => s.session.contentId,
          'id',
          'https://x.com/img.png',
        ),
      ]),
    );
    await imageOnly.close();

    final audioOnlyAudio = _FakeAudio();
    final audioOnly = ReaderBloc(
      audioPlayer: audioOnlyAudio,
      bookRepository: repo,
    );
    audioOnly.add(
      const LoadContent(
        BookContent(
          audioUrl: 'https://x.com/a.mp3',
          syriacText: 'x',
        ),
      ),
    );
    await expectLater(
      audioOnly.stream,
      emitsInOrder([
        const ReaderLoading(),
        isA<ReaderReady>(),
        isA<ReaderPlaying>().having(
          (s) => s.session.contentId,
          'id',
          'https://x.com/a.mp3',
        ),
      ]),
    );
    await audioOnly.close();
  });

  test('close cancels reader HTTP and disposes audio', () async {
    final localAudio = _FakeAudio();
    final localBloc = ReaderBloc(
      audioPlayer: localAudio,
      bookRepository: repo,
    );
    await localBloc.close();
    verify(() => repo.cancelRequests('reader')).called(greaterThanOrEqualTo(1));
    expect(localAudio.disposeCalls, 1);
  });
}
