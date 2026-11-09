import 'package:flutter/foundation.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/auth_failure_exception.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/errors/profile_creation_pending_exception.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';
import 'package:internal_request_app/domain/usecases/register_employee.dart';

enum RegisterEmployeeStatus {
  idle,
  submitting,
  success,
  validationFailure,
  authenticationFailure,
  profilePending,
  unexpectedFailure,
}

class RegisterEmployeeState {
  const RegisterEmployeeState({
    this.status = RegisterEmployeeStatus.idle,
    this.profile,
    this.validationError,
    this.authFailure,
    this.technicalError,
    this.stackTrace,
  });

  final RegisterEmployeeStatus status;
  final UserProfile? profile;
  final AuthValidationError? validationError;
  final AuthFailure? authFailure;

  // Se conserva para diagnóstico; la interfaz no debe mostrarlo directamente.
  final Object? technicalError;
  final StackTrace? stackTrace;
}

final class RegisterEmployeeViewModel extends ChangeNotifier {

  RegisterEmployeeViewModel(this._registerEmployee);

  final RegisterEmployee _registerEmployee;

  RegisterEmployeeState _state = const RegisterEmployeeState();
  bool _isDisposed = false;

  RegisterEmployeeState get state => _state;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {

    if (_state.status == RegisterEmployeeStatus.submitting) return;

    _emit(const RegisterEmployeeState(
      status: RegisterEmployeeStatus.submitting,
    ));

    try {
      final result = await _registerEmployee(
        name: name,
        email: email,
        password: password,
      );

      switch (result) {
        case Ok<UserProfile>():
          _emit(RegisterEmployeeState(
            status: RegisterEmployeeStatus.success,
            profile: result.value,
          ));
        case Error<UserProfile>():
          final error = result.error;

          if (error is AuthValidationException) {
            _emit(RegisterEmployeeState(
              status: RegisterEmployeeStatus.validationFailure,
              validationError: error.error,
            ));
          } else if (error is AuthFailureException) {
            _emit(RegisterEmployeeState(
              status: RegisterEmployeeStatus.authenticationFailure,
              authFailure: error.failure,
            ));
          } else if (error is ProfileCreationPendingException) {
            _emit(RegisterEmployeeState(
              status: RegisterEmployeeStatus.profilePending,
              profile: error.profile,
            ));
          } else {
            _emit(RegisterEmployeeState(
              status: RegisterEmployeeStatus.unexpectedFailure,
              technicalError: error,
            ));
          }
      }
    } on Object catch (error, stackTrace) {
      _emit(RegisterEmployeeState(
        status: RegisterEmployeeStatus.unexpectedFailure,
        technicalError: error,
        stackTrace: stackTrace,
      ));
    }
  }

  void reset() {
    _emit(const RegisterEmployeeState());
  }

  void _emit(RegisterEmployeeState state) {
    _state = state;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}