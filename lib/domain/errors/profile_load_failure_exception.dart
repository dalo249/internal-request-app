enum ProfileLoadFailure { permissionDenied, unavailable, invalidData, unknown }

final class ProfileLoadFailureException implements Exception {
  const ProfileLoadFailureException(this.failure);

  final ProfileLoadFailure failure;
}

final class AuthSessionFailureException implements Exception {
  const AuthSessionFailureException();
}
