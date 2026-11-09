import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/usecases/login_user.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  group('LoginUser', () {
    test('no llama al repositorio si el correo está vacío', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUser(repository);

      final result = await useCase(email: '', password: '123456');

      expect(repository.signInCallCount, 0);
      switch (result) {
        case Error<void>():
          expect(result.error, isA<AuthValidationException>());
          expect(
            (result.error as AuthValidationException).error,
            AuthValidationError.emailRequired,
          );
        case Ok<void>():
          fail('Se esperaba un error de validación.');
      }
    });

    test(
      'no llama al repositorio si el correo tiene formato inválido',
      () async {
        final repository = FakeAuthRepository();
        final useCase = LoginUser(repository);

        final result = await useCase(
          email: 'correo-invalido',
          password: '123456',
        );

        expect(repository.signInCallCount, 0);
        switch (result) {
          case Error<void>():
            expect(
              (result.error as AuthValidationException).error,
              AuthValidationError.emailInvalidFormat,
            );
          case Ok<void>():
            fail('Se esperaba un error de validación.');
        }
      },
    );

    test('no llama al repositorio si la contraseña está vacía', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUser(repository);

      final result = await useCase(email: 'ana@empresa.com', password: '');

      expect(repository.signInCallCount, 0);
      switch (result) {
        case Error<void>():
          expect(
            (result.error as AuthValidationException).error,
            AuthValidationError.passwordRequired,
          );
        case Ok<void>():
          fail('Se esperaba un error de validación.');
      }
    });

    test('acepta contraseña corta no vacía y normaliza el correo', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUser(repository);

      final result = await useCase(email: ' ana@empresa.com ', password: '1');

      expect(result, isA<Ok<void>>());
      expect(repository.signInCallCount, 1);
      expect(repository.receivedEmail, 'ana@empresa.com');
      expect(repository.receivedPassword, '1');
    });

    test('propaga el resultado de autenticación del repositorio', () async {
      final failure = Exception('Fallo de autenticación');
      final repository = FakeAuthRepository(
        signInResult: Result<void>.error(failure),
      );
      final useCase = LoginUser(repository);

      final result = await useCase(
        email: 'ana@empresa.com',
        password: '123456',
      );

      switch (result) {
        case Error<void>():
          expect(result.error, same(failure));
        case Ok<void>():
          fail('Se esperaba que el error del repositorio se propagara.');
      }
    });
  });
}
