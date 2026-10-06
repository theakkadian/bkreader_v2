import 'package:equatable/equatable.dart';

/// Domain-level failure types mapped to user messages in presentation.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class QrParseFailure extends Failure {
  const QrParseFailure([
    super.message = 'The QR Code you\'ve scanned is not a BETKANU Product',
  ]);
}

class ApiFailure extends Failure {
  const ApiFailure([
    super.message = 'Something went wrong!\nPlease try again later.',
  ]);
}

class MediaFailure extends Failure {
  const MediaFailure([super.message = 'Unable to play media.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Camera permission is required to scan QR codes.',
  ]);
}

class TextLoadFailure extends Failure {
  const TextLoadFailure([
    super.message = 'Something went wrong!\nPlease try again later.',
  ]);
}
