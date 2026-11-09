import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/repositories/auth_repository.dart';
import 'package:internal_request_app/domain/validators/auth_validators.dart';

final class LoginUser {
  LoginUser(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<void>> call({
    required String email,
    required String password,
  }) async {
    final validationError =
        AuthValidator.validateEmail(email) ??
        AuthValidator.validateLoginPassword(password);

    if (validationError != null) {
      return Result.error(AuthValidationException(validationError));
    }

    return _authRepository.signIn(email: email.trim(), password: password);
  }
}
