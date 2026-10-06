import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/utils/app_logger.dart';
import 'qr_scanner_port.dart';

/// [QrScannerPort] backed by `mobile_scanner` 7.x.
class MobileScannerQrAdapter implements QrScannerPort {
  MobileScannerQrAdapter({MobileScannerController? controller})
      : controller = controller ??
            MobileScannerController(
              facing: CameraFacing.back,
              detectionSpeed: DetectionSpeed.unrestricted,
              formats: const [BarcodeFormat.qrCode],
              autoZoom: true,
              // ScanPage owns start/stop via WidgetsBindingObserver; leave
              // autoStart off so MobileScanner does not race a manual start().
              autoStart: false,
            );

  /// Underlying controller for [MobileScanner] / [ScanWindowOverlay].
  final MobileScannerController controller;

  Future<void>? _startInFlight;

  @override
  bool get isRunning => controller.value.isRunning;

  @override
  bool get isTorchAvailable =>
      controller.value.torchState != TorchState.unavailable;

  @override
  bool get isTorchOn => controller.value.torchState == TorchState.on;

  @override
  Future<void> start() async {
    if (controller.value.isRunning) return;
    if (_startInFlight != null) {
      await _startInFlight;
      return;
    }
    final future = _doStart();
    _startInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_startInFlight, future)) {
        _startInFlight = null;
      }
    }
  }

  Future<void> _doStart() async {
    try {
      if (controller.value.isStarting || controller.value.isRunning) return;
      await controller.start();
    } catch (e, st) {
      AppLogger.e('QR scanner start failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (!controller.value.isRunning) return;
      await controller.pause();
    } catch (e, st) {
      AppLogger.e('QR scanner pause failed', e, st);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await controller.stop();
    } catch (e, st) {
      AppLogger.e('QR scanner stop failed', e, st);
    }
  }

  @override
  Future<void> toggleTorch() async {
    try {
      await controller.toggleTorch();
    } catch (e, st) {
      AppLogger.e('QR scanner torch toggle failed', e, st);
    }
  }

  @override
  Future<void> dispose() => controller.dispose();
}
