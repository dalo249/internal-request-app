import '../models/user_profile.dart';

final class ProfileCreationPendingException implements Exception {
  const ProfileCreationPendingException({
    required this.profile,
  });

  final UserProfile profile;

  @override
  String toString() =>
      'No se pudo confirmar la creación del perfil de usuario en firestore,para la sesion:${profile.uid}';
}
