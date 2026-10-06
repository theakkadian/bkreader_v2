part of 'scan_bloc.dart';

sealed class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

class ScanInitial extends ScanState {
  const ScanInitial();
}

class ScanDetecting extends ScanState {
  const ScanDetecting();
}

class ScanResolving extends ScanState {
  const ScanResolving();
}

class ScanSuccess extends ScanState {
  const ScanSuccess(this.content, {this.openedExternally = false});

  final BookContent content;
  final bool openedExternally;

  @override
  List<Object?> get props => [content, openedExternally];
}

class ScanFailure extends ScanState {
  const ScanFailure(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
