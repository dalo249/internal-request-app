import 'package:firebase_auth/firebase_auth.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/data/datasources/auth_remote_datasource.dart';
import 'package:internal_request_app/data/datasources/user_profile_remote_datasource.dart';
import 'package:internal_request_app/domain/errors/auth_failure_exception.dart';
import 'package:internal_request_app/domain/errors/profile_load_failure_exception.dart';
import 'package:internal_request_app/domain/enums/user_role.dart';
import 'package:internal_request_app/domain/errors/profile_creation_pending_exception.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';
import 'package:internal_request_app/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._authRemoteDataSource,
    this._userProfileRemoteDataSource,
  );

  static const _generalAreaId = '4';

  final AuthRemoteDataSource _authRemoteDataSource;
  final UserProfileRemoteDataSource _userProfileRemoteDataSource;

  @override
  Stream<Result<String?>> watchAuthenticatedUserId() async* {
    await for (final result
        in _authRemoteDataSource.watchAuthenticatedUserId()) {
      switch (result) {
        case Ok<String?>():
          yield Result.ok(result.value);
        case Error<String?>():
          yield Result.error(const AuthSessionFailureException());
      }
    }
  }

  @override
  Stream<Result<UserProfile?>> watchUserProfile(String uid) async* {
    await for (final result in _userProfileRemoteDataSource.watchProfile(uid)) {
      switch (result) {
        case Ok<UserProfile?>():
          yield Result.ok(result.value);
        case Error<UserProfile?>():
          yield Result.error(_mapProfileLoadFailure(result.error));
      }
    }
  }

  @override
  Future<Result<void>> signOut() async {
    final result = await _authRemoteDataSource.signOut();
    return switch (result) {
      Ok<void>() => Result.ok(null),
      Error<void>() => Result.error(const AuthSessionFailureException()),
    };
  }

  @override
  Future<Result<UserProfile>> registerEmployee({
    required String name,
    required String email,
    required String password,
  }) async {
    final accountResult = await _authRemoteDataSource.createAccount(
      email: email,
      password: password,
    );

    switch (accountResult) {
      case Error<User>():
        return Result.error(_mapAuthFailure(accountResult.error));
      case Ok<User>():
        final firebaseUser = accountResult.value;
        final profile = UserProfile(
          uid: firebaseUser.uid,
          name: name,
          email: firebaseUser.email ?? email,
          role: UserRole.employee,
          areaId: _generalAreaId,
        );

        //Crear usuario en firestore cuando autenticacion es exitosa
        final profileResult = await _userProfileRemoteDataSource.createProfile(
          profile,
        );

        switch (profileResult) {
          case Ok<void>():
            return Result.ok(profile);
          case Error<void>():
            return Result.error(
              ProfileCreationPendingException(profile: profile),
            );
        }
    }
  }

  ProfileLoadFailureException _mapProfileLoadFailure(Exception exception) {
    if (exception is FormatException) {
      return const ProfileLoadFailureException(ProfileLoadFailure.invalidData);
    }

    if (exception is FirebaseException) {
      final failure = switch (exception.code) {
        'permission-denied' => ProfileLoadFailure.permissionDenied,
        'unavailable' || 'deadline-exceeded' => ProfileLoadFailure.unavailable,
        _ => ProfileLoadFailure.unknown,
      };
      return ProfileLoadFailureException(failure);
    }

    return const ProfileLoadFailureException(ProfileLoadFailure.unknown);
  }

  //mapea erroes de firebase, a excepciones de dominio
  AuthFailureException _mapAuthFailure(Exception exception) {
    if (exception is! FirebaseAuthException) {
      return const AuthFailureException(AuthFailure.unknown);
    }

    final failure = switch (exception.code) {
      'email-already-in-use' => AuthFailure.emailAlreadyInUse,
      'invalid-email' => AuthFailure.invalidEmail,
      'weak-password' => AuthFailure.weakPassword,
      'network-request-failed' => AuthFailure.network,
      'too-many-requests' => AuthFailure.tooManyRequests,
      'operation-not-allowed' => AuthFailure.operationNotAllowed,
      _ => AuthFailure.unknown,
    };

    return AuthFailureException(failure);
  }
}
