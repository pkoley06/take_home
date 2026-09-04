sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'A local storage error occurred.']);
}

class PlatformFailure extends Failure {
  const PlatformFailure([
    super.message = 'Something went wrong talking to the device.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'That item could not be found.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something unexpected happened.']);
}
