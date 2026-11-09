
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';


class AuthValidator {

  static AuthValidationError? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AuthValidationError.nameRequired;
    }
    return null;
  }

  static AuthValidationError? validateEmail(String? value) {

    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return AuthValidationError.emailRequired;
    }

    if (!email.contains('@') || !email.contains('.')) {
      return AuthValidationError.emailInvalidFormat;
    }
    return null;
  }

  static AuthValidationError? validatePassword(String? value) {

    final password = value ?? '';
    if (password.isEmpty) {
      return AuthValidationError.passwordRequired;
    }
    if (password.length < 6) {
      return AuthValidationError.passwordTooShort;
    }
    return null;
  }
}