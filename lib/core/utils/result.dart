
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.error(Exception error) = Error<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Error<T> extends Result<T> {
  const Error(this.error);

  final Exception error;
}