import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/enums/user_role.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';
import 'package:internal_request_app/domain/repositories/auth_repository.dart';

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.result, this.onRegister, this.signInResult});

  final Result<UserProfile>? result;
  final Future<Result<UserProfile>> Function()? onRegister;
  final Result<void>? signInResult;

  int callCount = 0;
  int signInCallCount = 0;
  String? receivedName;
  String? receivedEmail;
  String? receivedPassword;

  bool get wasCalled => callCount > 0;

  @override
  Stream<Result<String?>> watchAuthenticatedUserId() =>
      Stream.value(Result.ok(null));

  @override
  Stream<Result<UserProfile?>> watchUserProfile(String uid) =>
      Stream.value(Result.ok(null));

  @override
  Future<Result<void>> signOut() async => Result.ok(null);

  @override
  Future<Result<UserProfile>> registerEmployee({
    required String name,
    required String email,
    required String password,
  }) async {
    callCount++;
    receivedName = name;
    receivedEmail = email;
    receivedPassword = password;

    final response = onRegister;
    if (response != null) {
      return response();
    }

    return result ??
        Result.ok(
          UserProfile(
            uid: 'test-uid',
            name: name,
            email: email,
            role: UserRole.employee,
            areaId: '4',
          ),
        );
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    receivedEmail = email;
    receivedPassword = password;

    return signInResult ?? Result.ok(null);
  }
}
