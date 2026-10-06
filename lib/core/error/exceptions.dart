/// Exceptions thrown by data layer; mapped to [Failure] in repositories.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

class ApiException extends AppException {
  const ApiException([super.message = 'API error']);
}

class QrParseException extends AppException {
  const QrParseException([super.message = 'Invalid QR']);
}

class MediaException extends AppException {
  const MediaException([super.message = 'Media error']);
}

class TextLoadException extends AppException {
  const TextLoadException([super.message = 'Text load error']);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied']);
}
