/// Thin lifecycle port over a camera QR scanner.
///
/// Keeps presentation free to swap scanner backends without leaking types into
/// domain. The concrete adapter may still expose a platform widget controller.
abstract class QrScannerPort {
  /// Starts (or resumes after [pause]) the camera and detection.
  Future<void> start();

  /// Pauses frame analysis without tearing down the session when possible.
  Future<void> pause();

  /// Fully stops the camera.
  Future<void> stop();

  /// Toggles the flashlight when available.
  Future<void> toggleTorch();

  /// Whether the camera is currently running.
  bool get isRunning;

  /// Whether torch hardware is available.
  bool get isTorchAvailable;

  /// Whether the torch is currently on.
  bool get isTorchOn;

  /// Releases native resources.
  Future<void> dispose();
}
