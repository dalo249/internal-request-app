enum AuthValidationError {
  nameRequired,
  emailRequired,
  emailInvalidFormat,
  passwordRequired,
  passwordTooShort,
}

final class AuthValidationException implements Exception {
  const AuthValidationException(this.error);

  final AuthValidationError error;

  @override
  String toString() => 'AuthValidationException($error)';
}
