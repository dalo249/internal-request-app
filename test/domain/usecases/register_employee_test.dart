import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';
import 'package:internal_request_app/domain/usecases/register_employee.dart';
import 'package:internal_request_app/domain/validators/auth_validators.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  group('AuthValidator', () {
    test('rechaza un nombre vacío', () {
      expect(
        AuthValidator.validateName('  '),
        AuthValidationError.nameRequired,
      );
    });

    test('rechaza un correo con formato inválido', () {
      expect(
        AuthValidator.validateEmail('correo-invalido'),
        AuthValidationError.emailInvalidFormat,
      );
    });

    test('rechaza una contraseña menor a seis caracteres', () {
      expect(
        AuthValidator.validatePassword('12345'),
        AuthValidationError.passwordTooShort,
      );
    });

    test('acepta los datos válidos', () {
      expect(AuthValidator.validateName('Ana'), isNull);
      expect(AuthValidator.validateEmail('ana@empresa.com'), isNull);
      expect(AuthValidator.validatePassword('123456'), isNull);
    });
  });

  group('RegisterEmployee', () {
    test('no llama al repositorio si la entrada es inválida', () async {
      final repository = FakeAuthRepository();
      final useCase = RegisterEmployee(repository);

      final result = await useCase(
        name: 'Ana',
        email: 'correo-invalido',
        password: '123456',
      );

      expect(repository.wasCalled, isFalse);

      switch (result) {
        case Error<UserProfile>():
          expect(result.error, isA<AuthValidationException>());
          expect(
            (result.error as AuthValidationException).error,
            AuthValidationError.emailInvalidFormat,
          );
        case Ok<UserProfile>():
          fail('Se esperaba un error de validación.');
      }
    });

    test('normaliza nombre y correo y delega al repositorio', () async {
      final repository = FakeAuthRepository();
      final useCase = RegisterEmployee(repository);

      final result = await useCase(
        name: ' Ana ',
        email: ' ana@empresa.com ',
        password: '123456',
      );

      expect(repository.wasCalled, isTrue);
      expect(repository.receivedName, 'Ana');
      expect(repository.receivedEmail, 'ana@empresa.com');
      expect(repository.receivedPassword, '123456');
      expect(result, isA<Ok<UserProfile>>());
    });
  });
}
