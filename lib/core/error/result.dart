/// Lightweight Result type for domain/data without third-party Either packages.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Err() => null,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Object failure) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Err(:final failure) => onFailure(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Object failure;
}
