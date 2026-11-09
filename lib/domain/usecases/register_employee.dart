import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';
import 'package:internal_request_app/domain/repositories/auth_repository.dart';
import 'package:internal_request_app/domain/validators/auth_validators.dart';


final class RegisterEmployee {
  RegisterEmployee(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<UserProfile>> call({
    required String name,
    required String email,
    required String password,
  }) async {
    final validationError =
        AuthValidator.validateName(name) ??
        AuthValidator.validateEmail(email) ??
        AuthValidator.validatePassword(password);

    if (validationError != null) {
      return Result.error(AuthValidationException(validationError));
    }

    return _authRepository.registerEmployee(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
  }
}
