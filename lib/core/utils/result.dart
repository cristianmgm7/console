import '../errors/failures.dart';

/// Sealed Result type for type-safe error handling
sealed class Result<T> {
  const Result();

  /// Fold pattern for exhaustive handling
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  });

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get value or null (use with caution)
  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };

  /// Get failure or null
  AppFailure? get failureOrNull => switch (this) {
    Success() => null,
    Failure(failure: final f) => f,
  };
}

/// Success result
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      onSuccess(value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failure result (non-generic)
final class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure<T> failure) onFailure,
  }) =>
      onFailure(this);

  @override
  String toString() => 'Failure($failure)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}

/// Helper extension for async results
extension ResultFuture<T> on Future<Result<T>> {
  Future<R> foldAsync<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) async {
    final result = await this;
    return result.fold(onSuccess: onSuccess, onFailure: onFailure);
  }
}

/// Helper to create success results
Success<T> success<T>(T value) => Success(value);

/// Helper to create failure results
Failure<T> failure<T>(AppFailure error) => Failure(error);
