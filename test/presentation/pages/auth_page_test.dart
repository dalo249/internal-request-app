import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/domain/usecases/login_user.dart';
import 'package:internal_request_app/domain/usecases/register_employee.dart';
import 'package:internal_request_app/presentation/pages/auth_page.dart';
import 'package:internal_request_app/presentation/viewmodels/login_user_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/register_employee_view_model.dart';
import 'package:provider/provider.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  testWidgets(
    'valida el formulario de registro antes de llamar al caso de uso',
    (tester) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  RegisterEmployeeViewModel(RegisterEmployee(repository)),
            ),
            ChangeNotifierProvider(
              create: (_) => LoginUserViewModel(LoginUser(repository)),
            ),
          ],
          child: const MaterialApp(
            home: AuthPage(initialMode: AuthPageMode.register),
          ),
        ),
      );

      expect(find.text('Crear cuenta'), findsNWidgets(2));
      expect(find.byType(TextFormField), findsNWidgets(3));

      await tester.tap(find.text('Registrarme'));
      await tester.pump();

      expect(find.text('Ingresa tu nombre.'), findsOneWidget);
      expect(repository.callCount, 0);
    },
  );

  testWidgets('conecta la pantalla de login con el flujo de autenticación', (
    tester,
  ) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                RegisterEmployeeViewModel(RegisterEmployee(repository)),
          ),
          ChangeNotifierProvider(
            create: (_) => LoginUserViewModel(LoginUser(repository)),
          ),
        ],
        child: const MaterialApp(
          home: AuthPage(initialMode: AuthPageMode.login),
        ),
      ),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(repository.callCount, 0);
    expect(repository.signInCallCount, 0);

    await tester.tap(find.text('Crear una cuenta'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Registrarme'), findsOneWidget);
  });

  testWidgets('valida los datos de login antes de llamar al repositorio', (
    tester,
  ) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                RegisterEmployeeViewModel(RegisterEmployee(repository)),
          ),
          ChangeNotifierProvider(
            create: (_) => LoginUserViewModel(LoginUser(repository)),
          ),
        ],
        child: const MaterialApp(
          home: AuthPage(initialMode: AuthPageMode.login),
        ),
      ),
    );

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Ingresa tu correo.'), findsOneWidget);
    expect(find.text('Ingresa una contraseña.'), findsOneWidget);
    expect(repository.signInCallCount, 0);
  });

  testWidgets('envía credenciales válidas al caso de uso', (tester) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                RegisterEmployeeViewModel(RegisterEmployee(repository)),
          ),
          ChangeNotifierProvider(
            create: (_) => LoginUserViewModel(LoginUser(repository)),
          ),
        ],
        child: const MaterialApp(
          home: AuthPage(initialMode: AuthPageMode.login),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@empresa.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(repository.signInCallCount, 1);
    expect(repository.receivedEmail, 'ana@empresa.com');
    expect(repository.receivedPassword, '123456');
    expect(find.text('Inicio de sesión correcto.'), findsOneWidget);
  });
}
