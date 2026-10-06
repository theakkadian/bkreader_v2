import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/audio/audio_player_port.dart';
import '../../../../shared/network/url_launcher_port.dart';
import '../../domain/entities/book_content.dart';
import '../../domain/entities/resolved_target.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/usecases/fetch_book_content_usecase.dart';
import '../../domain/usecases/load_book_text_usecase.dart';
import '../../domain/usecases/normalize_qr_url_usecase.dart';
import '../../domain/usecases/resolve_qr_usecase.dart';

part 'scan_event.dart';
part 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc({
    required ResolveQrUseCase resolveQr,
    required FetchBookContentUseCase fetchBookContent,
    required LoadBookTextUseCase loadBookText,
    required BookRepository bookRepository,
    required AudioPlayerPort sfxPlayer,
    required UrlLauncherPort urlLauncher,
    NormalizeQrUrlUseCase normalizeQrUrl = const NormalizeQrUrlUseCase(),
  })  : _resolveQr = resolveQr,
        _fetchBookContent = fetchBookContent,
        _loadBookText = loadBookText,
        _bookRepository = bookRepository,
        _sfxPlayer = sfxPlayer,
        _urlLauncher = urlLauncher,
        _normalizeQrUrl = normalizeQrUrl,
        super(const ScanInitial()) {
    on<ScanStarted>(_onStarted);
    on<QrDetected>(_onQrDetected);
    // Allow cancel/reset to interrupt an in-flight resolve (closes HTTP).
    on<ScanCancelled>(_onCancelled, transformer: _concurrent());
    on<ScanReset>(_onReset, transformer: _concurrent());
  }

  final ResolveQrUseCase _resolveQr;
  final FetchBookContentUseCase _fetchBookContent;
  final LoadBookTextUseCase _loadBookText;
  final BookRepository _bookRepository;
  final AudioPlayerPort _sfxPlayer;
  final UrlLauncherPort _urlLauncher;
  final NormalizeQrUrlUseCase _normalizeQrUrl;

  static const _cancelToken = 'scan';
  String? _lastRaw;
  DateTime? _lastDetectAt;
  bool _resolveInFlight = false;
  int _resolveGeneration = 0;

  Future<void> _onStarted(ScanStarted event, Emitter<ScanState> emit) async {
    emit(const ScanDetecting());
  }

  Future<void> _onQrDetected(QrDetected event, Emitter<ScanState> emit) async {
    final normalized = _normalizeQrUrl(event.raw);
    if (normalized.isEmpty) return;

    final now = DateTime.now();
    if (_resolveInFlight) return;
    if (_lastRaw == normalized &&
        _lastDetectAt != null &&
        now.difference(_lastDetectAt!) < AppConstants.qrDebounce) {
      return;
    }

    _lastRaw = normalized;
    _lastDetectAt = now;
    _resolveInFlight = true;
    final generation = ++_resolveGeneration;

    emit(const ScanResolving());

    // Fire-and-forget SFX — never delay network resolve.
    unawaited(_playScanSfx());

    try {
      final target = _resolveQr(normalized);

      if (target is InvalidTarget) {
        await _emitFailureThenDetecting(
          emit,
          generation,
          const QrParseFailure(),
        );
        return;
      }

      if (target is YoutubeTarget) {
        if (!_isActive(generation)) return;
        final launched = await _urlLauncher.launch(target.url);
        if (!_isActive(generation)) return;
        if (!launched) {
          await _emitFailureThenDetecting(
            emit,
            generation,
            const MediaFailure('Could not open YouTube link.'),
          );
          return;
        }
        emit(ScanSuccess(
          BookContent(videoUrl: target.url, isYoutube: true),
          openedExternally: true,
        ));
        return;
      }

      var content = await _fetchBookContent(
        target,
        cancelToken: _cancelToken,
      );
      if (!_isActive(generation)) return;

      final text = await _loadBookText(
        content.textUrl,
        cancelToken: _cancelToken,
      );
      if (!_isActive(generation)) return;

      content = content.copyWith(
        syriacText: text.syriacText,
        companionText: text.companionText,
        isOnlySyriac: text.isOnlySyriac,
      );

      emit(ScanSuccess(content));
    } on Failure catch (f) {
      if (!_isActive(generation)) return;
      await _emitFailureThenDetecting(emit, generation, f);
    } catch (e, st) {
      if (!_isActive(generation)) return;
      AppLogger.e('QR resolve failed', e, st);
      await _emitFailureThenDetecting(
        emit,
        generation,
        ApiFailure(e.toString()),
      );
    } finally {
      if (generation == _resolveGeneration) {
        _resolveInFlight = false;
      }
    }
  }

  Future<void> _playScanSfx() async {
    try {
      await _sfxPlayer.playAsset(AppConstants.scanAudioAsset);
    } catch (e, st) {
      AppLogger.e('Scan SFX failed', e, st);
    }
  }

  Future<void> _emitFailureThenDetecting(
    Emitter<ScanState> emit,
    int generation,
    Failure failure,
  ) async {
    if (!_isActive(generation)) return;
    emit(ScanFailure(failure));
    // Stay on scanner so the user can retry immediately.
    emit(const ScanDetecting());
  }

  bool _isActive(int generation) => generation == _resolveGeneration;

  Future<void> _onCancelled(
    ScanCancelled event,
    Emitter<ScanState> emit,
  ) async {
    _resolveGeneration++;
    _bookRepository.cancelRequests(_cancelToken);
    _resolveInFlight = false;
    emit(const ScanInitial());
  }

  Future<void> _onReset(ScanReset event, Emitter<ScanState> emit) async {
    _resolveGeneration++;
    _bookRepository.cancelRequests(_cancelToken);
    _resolveInFlight = false;
    _lastRaw = null;
    _lastDetectAt = null;
    emit(const ScanDetecting());
  }

  @override
  Future<void> close() {
    _resolveGeneration++;
    _bookRepository.cancelRequests(_cancelToken);
    return super.close();
  }
}

/// Runs handlers concurrently so cancel can interrupt an awaiting resolve.
EventTransformer<E> _concurrent<E>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
