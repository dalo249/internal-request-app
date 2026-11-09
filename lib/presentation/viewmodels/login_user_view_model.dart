import 'package:flutter/foundation.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/auth_failure_exception.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/usecases/login_user.dart';

enum LoginUserStatus {
  idle,
  submitting,
  success,
  validationFailure,
  authenticationFailure,
  unexpectedFailure,
}

class LoginUserState {
  const LoginUserState({
    this.status = LoginUserStatus.idle,
    this.validationError,
    this.authFailure,
    this.technicalError,
    this.stackTrace,
  });

  final LoginUserStatus status;
  final AuthValidationError? validationError;
  final AuthFailure? authFailure;
  final Object? technicalError;
  final StackTrace? stackTrace;
}

final class LoginUserViewModel extends ChangeNotifier {
  LoginUserViewModel(this._loginUser);

  final LoginUser _loginUser;

  LoginUserState _state = const LoginUserState();
  bool _isDisposed = false;

  LoginUserState get state => _state;

  Future<void> login({required String email, required String password}) async {
    if (_state.status == LoginUserStatus.submitting) return;

    _emit(const LoginUserState(status: LoginUserStatus.submitting));

    try {
      final result = await _loginUser(email: email, password: password);

      switch (result) {
        case Ok<void>():
          _emit(const LoginUserState(status: LoginUserStatus.success));
        case Error<void>():
          final error = result.error;

          if (error is AuthValidationException) {
            _emit(
              LoginUserState(
                status: LoginUserStatus.validationFailure,
                validationError: error.error,
              ),
            );
          } else if (error is AuthFailureException) {
            _emit(
              LoginUserState(
                status: LoginUserStatus.authenticationFailure,
                authFailure: error.failure,
              ),
            );
          } else {
            _emit(
              LoginUserState(
                status: LoginUserStatus.unexpectedFailure,
                technicalError: error,
              ),
            );
          }
      }
    } on Object catch (error, stackTrace) {
      _emit(
        LoginUserState(
          status: LoginUserStatus.unexpectedFailure,
          technicalError: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  void reset() {
    _emit(const LoginUserState());
  }

  void _emit(LoginUserState state) {
    _state = state;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
