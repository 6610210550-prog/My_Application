sealed class Result<T> {
  static Ok<T> ok<T>(T value) => Ok(value);
  static Error<T> error<T>(Exception error) => Error(error);
}

class Ok<T> extends Result<T> {
  final T value;
  Ok(this.value);
}

class Error<T> extends Result<T> {
  final Exception error;
  Error(this.error);
}