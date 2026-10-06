import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/scanner/mobile_scanner_qr_adapter.dart';
import '../bloc/scan_bloc.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  late final MobileScannerQrAdapter _scanner;
  bool _detectFlash = false;
  bool _permissionDenied = false;
  bool _pageVisible = true;
  bool _handlingDetect = false;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerQrAdapter();
    WidgetsBinding.instance.addObserver(this);
    // ScanStarted may already have emitted ScanDetecting before this page
    // mounts, so the Bloc listener never fires for that transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resumeIfDetecting());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_scanner.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Own lifecycle: MobileScanner skips observer when an external controller
    // is supplied. Resume only while this page is visible and detecting.
    switch (state) {
      case AppLifecycleState.resumed:
        _pageVisible = true;
        unawaited(_resumeIfDetecting());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pageVisible = false;
        unawaited(_scanner.stop());
    }
  }

  Future<void> _resumeIfDetecting() async {
    if (!mounted || !_pageVisible || _permissionDenied) return;
    final scanState = context.read<ScanBloc>().state;
    if (scanState is! ScanDetecting) return;
    try {
      await _scanner.start();
    } catch (e, st) {
      AppLogger.e('Failed to resume scanner', e, st);
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  Future<void> _pauseScanner() async {
    await _scanner.pause();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingDetect || _permissionDenied || !_pageVisible) return;
    final blocState = context.read<ScanBloc>().state;
    if (blocState is! ScanDetecting) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _handlingDetect = true;

    // Pause immediately for snappy perceived lock + single-flight resolve.
    await _pauseScanner();
    if (!mounted) return;

    setState(() => _detectFlash = true);
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _detectFlash = false);
    });

    context.read<ScanBloc>().add(QrDetected(raw));
  }

  void _close() {
    context.read<ScanBloc>().add(const ScanCancelled());
    context.pop();
  }

  Future<void> _retryPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _permissionDenied = false);
      await _resumeIfDetecting();
      return;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanBloc, ScanState>(
      listenWhen: (previous, current) =>
          current is ScanSuccess ||
          current is ScanFailure ||
          current is ScanResolving ||
          current is ScanDetecting,
      listener: (context, state) {
        if (state is ScanSuccess) {
          if (state.openedExternally) {
            context.pop();
            return;
          }
          context.pop(state.content);
          return;
        }
        if (state is ScanFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          return;
        }
        if (state is ScanResolving) {
          unawaited(_pauseScanner());
          return;
        }
        if (state is ScanDetecting) {
          _handlingDetect = false;
          unawaited(_resumeIfDetecting());
        }
      },
      builder: (context, state) {
        final resolving = state is ScanResolving;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                // Cap scan frame so tablets don't get an oversized box.
                final side = (size.shortestSide * 0.72).clamp(220.0, 420.0);
                final scanWindow = Rect.fromCenter(
                  center: Offset(size.width / 2, size.height * 0.42),
                  width: side,
                  height: side,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!_permissionDenied)
                      MobileScanner(
                        controller: _scanner.controller,
                        // We own lifecycle via WidgetsBindingObserver.
                        useAppLifecycleState: false,
                        scanWindow: scanWindow,
                        onDetect: (capture) => unawaited(_onDetect(capture)),
                        errorBuilder: (context, error) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted &&
                                error.errorCode ==
                                    MobileScannerErrorCode.permissionDenied) {
                              setState(() => _permissionDenied = true);
                            }
                          });
                          return const ColoredBox(color: Colors.black);
                        },
                      ),
                    if (!_permissionDenied)
                      ScanWindowOverlay(
                        controller: _scanner.controller,
                        scanWindow: scanWindow,
                        borderColor: _detectFlash
                            ? Colors.lightGreenAccent
                            : Colors.white,
                        borderWidth: _detectFlash ? 4 : 2.5,
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0x99000000),
                      ),
                    if (_detectFlash)
                      const ColoredBox(
                        color: Color(0x33FFFFFF),
                      ),
                    if (_permissionDenied)
                      _PermissionDeniedPanel(
                        onClose: _close,
                        onRetry: _retryPermission,
                        onOpenSettings: openAppSettings,
                      ),
                    if (resolving)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.loaderBlue,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading book…',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_permissionDenied && !resolving)
                      Positioned(
                        left: 24,
                        right: 24,
                        top: scanWindow.bottom + 20,
                        child: const Text(
                          'Align the QR code inside the frame',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _close,
                      ),
                    ),
                    if (!_permissionDenied)
                      Positioned(
                        top: 8,
                        right: 4,
                        child: ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _scanner.controller,
                          builder: (context, scannerState, _) {
                            final torch = scannerState.torchState;
                            if (torch == TorchState.unavailable) {
                              return const SizedBox.shrink();
                            }
                            final on = torch == TorchState.on;
                            return IconButton(
                              tooltip: on ? 'Torch off' : 'Torch on',
                              icon: Icon(
                                on ? Icons.flash_on : Icons.flash_off,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  unawaited(_scanner.toggleTorch()),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PermissionDeniedPanel extends StatelessWidget {
  const _PermissionDeniedPanel({
    required this.onClose,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final VoidCallback onClose;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                const PermissionFailure().message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: onClose,
                    child: const Text('Close', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onOpenSettings,
                    child: const Text('Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
