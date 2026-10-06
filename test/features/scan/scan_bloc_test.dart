import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bk_reader_v2/core/error/failures.dart';
import 'package:bk_reader_v2/features/reader/domain/entities/book_text.dart';
import 'package:bk_reader_v2/features/scan/domain/entities/book_content.dart';
import 'package:bk_reader_v2/features/scan/domain/entities/resolved_target.dart';
import 'package:bk_reader_v2/features/scan/domain/repositories/book_repository.dart';
import 'package:bk_reader_v2/features/scan/domain/usecases/fetch_book_content_usecase.dart';
import 'package:bk_reader_v2/features/scan/domain/usecases/load_book_text_usecase.dart';
import 'package:bk_reader_v2/features/scan/domain/usecases/normalize_qr_url_usecase.dart';
import 'package:bk_reader_v2/features/scan/domain/usecases/resolve_qr_usecase.dart';
import 'package:bk_reader_v2/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:bk_reader_v2/shared/audio/audio_player_port.dart';
import 'package:bk_reader_v2/shared/network/url_launcher_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements BookRepository {}

class _MockFetch extends Mock implements FetchBookContentUseCase {}

class _MockLoadText extends Mock implements LoadBookTextUseCase {}

class _FakeAudio implements AudioPlayerPort {
  int playAssetCalls = 0;
  final Completer<void> playStarted = Completer<void>();
  final Completer<void> allowComplete = Completer<void>();

  @override
  Stream<AudioPlaybackState> get stateStream => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> playAsset(String assetPath) async {
    playAssetCalls++;
    if (!playStarted.isCompleted) playStarted.complete();
    await allowComplete.future;
  }

  @override
  Future<void> playUrl(String url) async {}

  @override
  Future<void> stop() async {}
}

class _FakeUrlLauncher implements UrlLauncherPort {
  final List<String> launched = [];
  bool succeed = true;

  @override
  Future<bool> launch(String url) async {
    launched.add(url);
    return succeed;
  }
}

void main() {
  late _MockRepo repo;
  late _MockFetch fetch;
  late _MockLoadText loadText;
  late ResolveQrUseCase resolve;
  late _FakeAudio audio;
  late _FakeUrlLauncher urlLauncher;
  late ScanBloc bloc;
  Completer<BookContent>? inFlightGate;

  setUpAll(() {
    registerFallbackValue(const InvalidTarget());
    registerFallbackValue(const BookContent());
  });

  setUp(() {
    repo = _MockRepo();
    fetch = _MockFetch();
    loadText = _MockLoadText();
    resolve = ResolveQrUseCase(const NormalizeQrUrlUseCase());
    audio = _FakeAudio()..allowComplete.complete();
    urlLauncher = _FakeUrlLauncher();
    when(() => repo.cancelRequests(any())).thenReturn(null);

    bloc = ScanBloc(
      resolveQr: resolve,
      fetchBookContent: fetch,
      loadBookText: loadText,
      bookRepository: repo,
      sfxPlayer: audio,
      urlLauncher: urlLauncher,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  blocTest<ScanBloc, ScanState>(
    'emits detecting on ScanStarted',
    build: () => bloc,
    act: (b) => b.add(const ScanStarted()),
    expect: () => [const ScanDetecting()],
  );

  blocTest<ScanBloc, ScanState>(
    'happy path: BetKanu API QR → ScanSuccess with text',
    build: () {
      when(() => fetch(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer(
        (_) async => const BookContent(
          imageUrl: 'https://x.com/a.png',
          textUrl: 'https://x.com/t.txt',
          audioUrl: 'https://x.com/a.mp3',
          textLanguage: 'eastern',
        ),
      );
      when(() => loadText(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer(
        (_) async => const BookText(syriacText: 'ܫܠܡܐ', isOnlySyriac: true),
      );
      return bloc;
    },
    act: (b) => b.add(
      const QrDetected('https://www.betkanu.com/api?book=1&page=2'),
    ),
    expect: () => [
      const ScanResolving(),
      isA<ScanSuccess>().having(
        (s) => s.content.syriacText,
        'syriac',
        'ܫܠܡܐ',
      ),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'normalizes whitespace before resolve',
    build: () {
      when(() => fetch(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => const BookContent(textUrl: null));
      when(() => loadText(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => const BookText(syriacText: ''));
      return bloc;
    },
    act: (b) => b.add(
      const QrDetected('  https://www.betkanu.com/r?book=1\n '),
    ),
    expect: () => [
      const ScanResolving(),
      isA<ScanSuccess>(),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'invalid QR → ScanFailure then ScanDetecting (stay on scanner)',
    build: () => bloc,
    act: (b) => b.add(const QrDetected('https://evil.example/qr')),
    expect: () => [
      const ScanResolving(),
      isA<ScanFailure>().having(
        (s) => s.failure,
        'failure',
        isA<QrParseFailure>(),
      ),
      const ScanDetecting(),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'API throws → ScanFailure then ScanDetecting for retry',
    build: () {
      when(() => fetch(any(), cancelToken: any(named: 'cancelToken')))
          .thenThrow(const ApiFailure());
      return bloc;
    },
    act: (b) =>
        b.add(const QrDetected('https://www.betkanu.com/r?book=1')),
    expect: () => [
      const ScanResolving(),
      isA<ScanFailure>().having(
        (s) => s.failure,
        'failure',
        isA<ApiFailure>(),
      ),
      const ScanDetecting(),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'youtube QR opens externally and succeeds',
    build: () => bloc,
    act: (b) => b.add(const QrDetected('https://youtu.be/abc123')),
    expect: () => [
      const ScanResolving(),
      isA<ScanSuccess>()
          .having((s) => s.openedExternally, 'external', isTrue)
          .having((s) => s.content.isYoutube, 'youtube', isTrue),
    ],
    verify: (_) {
      expect(urlLauncher.launched, ['https://youtu.be/abc123']);
    },
  );

  blocTest<ScanBloc, ScanState>(
    'duplicate QR within debounce is ignored',
    build: () {
      when(() => fetch(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => const BookContent());
      when(() => loadText(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => const BookText(syriacText: ''));
      return bloc;
    },
    act: (b) async {
      const raw = 'https://www.betkanu.com/r?book=1';
      b.add(const QrDetected(raw));
      await Future<void>.delayed(Duration.zero);
      b.add(const QrDetected(raw));
    },
    expect: () => [
      const ScanResolving(),
      isA<ScanSuccess>(),
    ],
    verify: (_) {
      verify(() => fetch(any(), cancelToken: any(named: 'cancelToken')))
          .called(1);
    },
  );

  blocTest<ScanBloc, ScanState>(
    'different raw while in-flight is ignored',
    build: () {
      final gate = Completer<BookContent>();
      when(() => fetch(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) => gate.future);
      when(() => loadText(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => const BookText(syriacText: ''));
      inFlightGate = gate;
      return bloc;
    },
    act: (b) async {
      b.add(const QrDetected('https://www.betkanu.com/r?book=1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const QrDetected('https://www.betkanu.com/r?book=2'));
      await Future<void>.delayed(Duration.zero);
      inFlightGate!.complete(const BookContent());
    },
    expect: () => [
      const ScanResolving(),
      isA<ScanSuccess>(),
    ],
    verify: (_) {
      verify(() => fetch(any(), cancelToken: any(named: 'cancelToken')))
          .called(1);
    },
  );

  blocTest<ScanBloc, ScanState>(
    'cancel mid-fetch cancels HTTP and does not emit success',
    build: () {
      final gate = Completer<BookContent>();
      when(() => fetch(any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) => gate.future);
      return bloc;
    },
    act: (b) async {
      b.add(const QrDetected('https://www.betkanu.com/r?book=1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ScanCancelled());
    },
    expect: () => [
      const ScanResolving(),
      const ScanInitial(),
    ],
    verify: (_) {
      verify(() => repo.cancelRequests('scan')).called(greaterThanOrEqualTo(1));
    },
  );

  test('SFX does not block resolve start', () async {
    final slowAudio = _FakeAudio(); // allowComplete not completed
    final delayedFetch = Completer<BookContent>();
    final localFetch = _MockFetch();
    final localLoad = _MockLoadText();
    when(() => localFetch(any(), cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) => delayedFetch.future);
    when(() => localLoad(any(), cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => const BookText(syriacText: ''));

    final localBloc = ScanBloc(
      resolveQr: resolve,
      fetchBookContent: localFetch,
      loadBookText: localLoad,
      bookRepository: repo,
      sfxPlayer: slowAudio,
      urlLauncher: urlLauncher,
    );

    localBloc.add(const QrDetected('https://www.betkanu.com/r?book=1'));

    await slowAudio.playStarted.future.timeout(const Duration(seconds: 1));
    // Fetch should already have been invoked even though SFX is still playing.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verify(() => localFetch(any(), cancelToken: any(named: 'cancelToken')))
        .called(1);

    delayedFetch.complete(const BookContent());
    slowAudio.allowComplete.complete();
    await localBloc.close();
  });
}
