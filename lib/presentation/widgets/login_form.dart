import 'package:flutter/material.dart';
import 'package:internal_request_app/domain/errors/auth_failure_exception.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/validators/auth_validators.dart';
import 'package:internal_request_app/presentation/viewmodels/login_user_view_model.dart';
import 'package:provider/provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<LoginUserViewModel>().login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _clearFailureWhenEditing() {
    final viewModel = context.read<LoginUserViewModel>();
    final status = viewModel.state.status;
    if (status == LoginUserStatus.validationFailure ||
        status == LoginUserStatus.authenticationFailure ||
        status == LoginUserStatus.unexpectedFailure) {
      viewModel.reset();
    }
  }

  String? _validationMessage(AuthValidationError? error) => switch (error) {
    AuthValidationError.emailRequired => 'Ingresa tu correo.',
    AuthValidationError.emailInvalidFormat => 'Ingresa un correo con formato válido.',
    AuthValidationError.passwordRequired => 'Ingresa una contraseña.',
    AuthValidationError.nameRequired ||
    AuthValidationError.passwordTooShort ||
    null => null,
  };

  String? _authFailureMessage(AuthFailure? failure) => switch (failure) {
    AuthFailure.network =>
      'Revisa tu conexión a internet e inténtalo de nuevo.',
    AuthFailure.tooManyRequests =>
      'Hubo demasiados intentos. Espera un momento e inténtalo de nuevo.',
    AuthFailure.operationNotAllowed =>
      'El inicio de sesión con correo y contraseña no está habilitado.',
    AuthFailure.emailAlreadyInUse ||
    AuthFailure.invalidEmail ||
    AuthFailure.weakPassword ||
    AuthFailure.unknown ||
    null =>
      'No se pudo iniciar sesión. Verifica tus credenciales e inténtalo '
          'de nuevo.',
  };

  String? _operationMessage(LoginUserState state) => switch (state.status) {
    LoginUserStatus.success => 'Inicio de sesión correcto.',
    LoginUserStatus.validationFailure => _validationMessage(
      state.validationError,
    ),
    LoginUserStatus.authenticationFailure => _authFailureMessage(
      state.authFailure,
    ),
    LoginUserStatus.unexpectedFailure =>
      'Ocurrió un error inesperado. Inténtalo más tarde.',
    _ => null,
  };

  String? _validateEmail(String? value) =>
      _validationMessage(AuthValidator.validateEmail(value));

  String? _validatePassword(String? value) =>
      _validationMessage(AuthValidator.validateLoginPassword(value));

  @override
  Widget build(BuildContext context) {
    final loginState = context.watch<LoginUserViewModel>().state;
    final isSubmitting = loginState.status == LoginUserStatus.submitting;
    final loginSucceeded = loginState.status == LoginUserStatus.success;
    final operationMessage = _operationMessage(loginState);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            enabled: !isSubmitting && !loginSucceeded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Correo',
              border: OutlineInputBorder(),
            ),
            validator: _validateEmail,
            onChanged: (_) => _clearFailureWhenEditing(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            enabled: !isSubmitting && !loginSucceeded,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
            ),
            validator: _validatePassword,
            onChanged: (_) => _clearFailureWhenEditing(),
            onFieldSubmitted: (_) {
              if (!isSubmitting && !loginSucceeded) {
                _submit();
              }
            },
          ),
          if (operationMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              operationMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: loginSucceeded
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isSubmitting || loginSucceeded ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ingresar'),
          ),
        ],
      ),
    );
  }
}
