import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/domain/usecases/register_employee.dart';
import 'package:internal_request_app/presentation/pages/auth_page.dart';
import 'package:internal_request_app/presentation/viewmodels/register_employee_view_model.dart';
import 'package:provider/provider.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  testWidgets(
    'valida el formulario de registro antes de llamar al caso de uso',
    (tester) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) =>
              RegisterEmployeeViewModel(RegisterEmployee(repository)),
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

  testWidgets('muestra la pantalla de login sin habilitar autenticación', (
    tester,
  ) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RegisterEmployeeViewModel(RegisterEmployee(repository)),
        child: const MaterialApp(
          home: AuthPage(initialMode: AuthPageMode.login),
        ),
      ),
    );

    expect(
      find.text(
        'El inicio de sesión se implementará en un paso '
        'posterior.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(repository.callCount, 0);

    await tester.tap(find.text('Crear una cuenta'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Registrarme'), findsOneWidget);
  });
}
