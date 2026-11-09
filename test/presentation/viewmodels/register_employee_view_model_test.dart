import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/auth_failure_exception.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/errors/profile_creation_pending_exception.dart';
import 'package:internal_request_app/domain/enums/user_role.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';
import 'package:internal_request_app/domain/usecases/register_employee.dart';
import 'package:internal_request_app/presentation/viewmodels/register_employee_view_model.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  const validName = 'Ana';
  const validEmail = 'ana@empresa.com';
  const validPassword = '123456';

  UserProfile createProfile() => const UserProfile(
    uid: 'test-uid',
    name: validName,
    email: validEmail,
    role: UserRole.employee,
    areaId: '4',
  );

  group('RegisterEmployeeViewModel', () {
    test('emite success y expone el perfil al completar el registro', () async {
      final profile = createProfile();
      final repository = FakeAuthRepository(result: Result.ok(profile));
      final viewModel = RegisterEmployeeViewModel(RegisterEmployee(repository));
      addTearDown(viewModel.dispose);

      await viewModel.register(
        name: validName,
        email: validEmail,
        password: validPassword,
      );

      expect(viewModel.state.status, RegisterEmployeeStatus.success);
      expect(viewModel.state.profile, same(profile));
      expect(repository.callCount, 1);
    });

    test('expone el error de validación sin llamar al repositorio', () async {
      final repository = FakeAuthRepository();
      final viewModel = RegisterEmployeeViewModel(RegisterEmployee(repository));
      addTearDown(viewModel.dispose);

      await viewModel.register(
        name: validName,
        email: 'correo-invalido',
        password: validPassword,
      );

      expect(viewModel.state.status, RegisterEmployeeStatus.validationFailure);
      expect(
        viewModel.state.validationError,
        AuthValidationError.emailInvalidFormat,
      );
      expect(repository.callCount, 0);
    });

    test('expone el fallo de autenticación tipado', () async {
      final repository = FakeAuthRepository(
        result: Result.error(
          const AuthFailureException(AuthFailure.emailAlreadyInUse),
        ),
      );
      final viewModel = RegisterEmployeeViewModel(RegisterEmployee(repository));
      addTearDown(viewModel.dispose);

      await viewModel.register(
        name: validName,
        email: validEmail,
        password: validPassword,
      );

      expect(
        viewModel.state.status,
        RegisterEmployeeStatus.authenticationFailure,
      );
      expect(viewModel.state.authFailure, AuthFailure.emailAlreadyInUse);
    });

    test(
      'expone profilePending con el perfil que requiere recuperación',
      () async {
        final profile = createProfile();
        final repository = FakeAuthRepository(
          result: Result.error(
            ProfileCreationPendingException(profile: profile),
          ),
        );
        final viewModel = RegisterEmployeeViewModel(
          RegisterEmployee(repository),
        );
        addTearDown(viewModel.dispose);

        await viewModel.register(
          name: validName,
          email: validEmail,
          password: validPassword,
        );

        expect(viewModel.state.status, RegisterEmployeeStatus.profilePending);
        expect(viewModel.state.profile, same(profile));
      },
    );

    test('expone unexpectedFailure para un error no tipado', () async {
      final error = Exception('Error no previsto');
      final repository = FakeAuthRepository(result: Result.error(error));
      final viewModel = RegisterEmployeeViewModel(RegisterEmployee(repository));
      addTearDown(viewModel.dispose);

      await viewModel.register(
        name: validName,
        email: validEmail,
        password: validPassword,
      );

      expect(viewModel.state.status, RegisterEmployeeStatus.unexpectedFailure);
      expect(viewModel.state.technicalError, same(error));
    });

    test(
      'captura excepciones inesperadas y conserva error y stack trace',
      () async {
        final error = StateError('Fallo inesperado');
        final repository = FakeAuthRepository(
          onRegister: () => Future<Result<UserProfile>>.error(error),
        );
        final viewModel = RegisterEmployeeViewModel(
          RegisterEmployee(repository),
        );
        addTearDown(viewModel.dispose);

        await viewModel.register(
          name: validName,
          email: validEmail,
          password: validPassword,
        );

        expect(
          viewModel.state.status,
          RegisterEmployeeStatus.unexpectedFailure,
        );
        expect(viewModel.state.technicalError, same(error));
        expect(viewModel.state.stackTrace, isNotNull);
      },
    );

    test(
      'ignora envíos adicionales mientras el registro está en curso',
      () async {
        final responseCompleter = Completer<Result<UserProfile>>();
        final repository = FakeAuthRepository(
          onRegister: () => responseCompleter.future,
        );
        final viewModel = RegisterEmployeeViewModel(
          RegisterEmployee(repository),
        );
        addTearDown(viewModel.dispose);

        final firstSubmission = viewModel.register(
          name: validName,
          email: validEmail,
          password: validPassword,
        );

        expect(viewModel.state.status, RegisterEmployeeStatus.submitting);

        await viewModel.register(
          name: validName,
          email: validEmail,
          password: validPassword,
        );

        expect(repository.callCount, 1);

        responseCompleter.complete(Result.ok(createProfile()));
        await firstSubmission;

        expect(viewModel.state.status, RegisterEmployeeStatus.success);
        expect(repository.callCount, 1);
      },
    );

    test('reset devuelve el ViewModel al estado idle', () async {
      final viewModel = RegisterEmployeeViewModel(
        RegisterEmployee(FakeAuthRepository()),
      );
      addTearDown(viewModel.dispose);

      await viewModel.register(
        name: validName,
        email: validEmail,
        password: validPassword,
      );
      viewModel.reset();

      expect(viewModel.state.status, RegisterEmployeeStatus.idle);
      expect(viewModel.state.profile, isNull);
      expect(viewModel.state.validationError, isNull);
      expect(viewModel.state.authFailure, isNull);
    });
  });
}
