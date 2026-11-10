enum AuthFailure {
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  network,
  tooManyRequests,
  operationNotAllowed,
  unknown,
}

final class AuthFailureException implements Exception {
  const AuthFailureException(this.failure);

  final AuthFailure failure;
}
