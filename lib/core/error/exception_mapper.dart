import '../error/exceptions.dart';
import '../error/failures.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is Failure) return error;
  if (error is NetworkException) return NetworkFailure(error.message);
  if (error is ApiException) return ApiFailure(error.message);
  if (error is QrParseException) return QrParseFailure(error.message);
  if (error is MediaException) return MediaFailure(error.message);
  if (error is PermissionException) return PermissionFailure(error.message);
  if (error is TextLoadException) return TextLoadFailure(error.message);
  return ApiFailure(error.toString());
}
