/// Domain-level error type. UI layer should display [message] to the user.
class Failure implements Exception {
  final String message;
  final int? code;
  const Failure(this.message, {this.code});

  @override
  String toString() =>
      code == null ? 'Failure: $message' : 'Failure($code): $message';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message) : super(code: 401);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message) : super(code: 0);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}
