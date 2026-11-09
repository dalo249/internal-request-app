import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/result.dart';

final class AuthRemoteDataSource {
  AuthRemoteDataSource({required this._firebaseAuth});

  final FirebaseAuth _firebaseAuth;

  Stream<Result<String?>> watchAuthenticatedUserId() async* {
    try {
      await for (final user in _firebaseAuth.authStateChanges()) {
        yield Result.ok(user?.uid);
      }
    } on Exception catch (exception) {
      yield Result.error(exception);
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return Result.ok(null);
    } on Exception catch (exception) {
      return Result.error(exception);
    }
  }

  Future<Result<User>> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return Result.error(const AuthAccountCreationException());
      }
      return Result.ok(user);
    } on FirebaseAuthException catch (exception) {
      return Result.error(exception);
    } on Exception catch (exception) {
      return Result.error(exception);
    }
  }
}

final class AuthAccountCreationException implements Exception {
  const AuthAccountCreationException();

  @override
  String toString() => 'Firebase no devolvió el usuario recien creado.';
}
