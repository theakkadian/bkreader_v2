part of 'scan_bloc.dart';

sealed class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object?> get props => [];
}

class ScanStarted extends ScanEvent {
  const ScanStarted();
}

class QrDetected extends ScanEvent {
  const QrDetected(this.raw);
  final String raw;

  @override
  List<Object?> get props => [raw];
}

class ScanCancelled extends ScanEvent {
  const ScanCancelled();
}

class ScanReset extends ScanEvent {
  const ScanReset();
}
