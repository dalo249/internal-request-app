import 'package:internal_request_app/core/utils/result.dart';

import '../models/user_profile.dart';

abstract interface class AuthRepository {
  Stream<Result<String?>> watchAuthenticatedUserId();

  Stream<Result<UserProfile?>> watchUserProfile(String uid);

  Future<Result<void>> signOut();

  Future<Result<UserProfile>> registerEmployee({
    required String name,
    required String email,
    required String password,
  });
}
