import 'package:flutter/material.dart';
import 'package:internal_request_app/domain/errors/auth_failure_exception.dart';
import 'package:internal_request_app/domain/errors/auth_validation_exception.dart';
import 'package:internal_request_app/domain/validators/auth_validators.dart';
import 'package:internal_request_app/presentation/viewmodels/register_employee_view_model.dart';
import 'package:provider/provider.dart';

class RegisterEmployeeForm extends StatefulWidget {
  const RegisterEmployeeForm({super.key});

  @override
  State<RegisterEmployeeForm> createState() => _RegisterEmployeeFormState();
}

class _RegisterEmployeeFormState extends State<RegisterEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<RegisterEmployeeViewModel>();
    await viewModel.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    final status = viewModel.state.status;
    if (status == RegisterEmployeeStatus.success ||
        status == RegisterEmployeeStatus.profilePending) {
      _passwordController.clear();
    }
  }

  void _clearFailureWhenEditing() {
    final viewModel = context.read<RegisterEmployeeViewModel>();
    final status = viewModel.state.status;
    if (status == RegisterEmployeeStatus.validationFailure ||
        status == RegisterEmployeeStatus.authenticationFailure ||
        status == RegisterEmployeeStatus.unexpectedFailure) {
      viewModel.reset();
    }
  }

  String? _validationMessage(AuthValidationError? error) => switch (error) {
    AuthValidationError.nameRequired => 'Ingresa tu nombre.',
    AuthValidationError.emailRequired => 'Ingresa tu correo.',
    AuthValidationError.emailInvalidFormat =>
      'Ingresa un correo con formato válido.',
    AuthValidationError.passwordRequired => 'Ingresa una contraseña.',
    AuthValidationError.passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.',
    null => null,
  };

  String? _authFailureMessage(AuthFailure? failure) => switch (failure) {
    AuthFailure.emailAlreadyInUse => 'Ya existe una cuenta con ese correo.',
    AuthFailure.invalidEmail => 'Ingresa un correo con formato válido.',
    AuthFailure.weakPassword => 'La contraseña no cumple los requisitos.',
    AuthFailure.network =>
      'Revisa tu conexión a internet e inténtalo de nuevo.',
    AuthFailure.tooManyRequests =>
      'Hubo demasiados intentos. Espera un momento e inténtalo de nuevo.',
    AuthFailure.operationNotAllowed =>
      'El registro con correo y contraseña no está habilitado.',
    AuthFailure.unknown => 'No fue posible completar el registro.',
    null => null,
  };

  String? _operationMessage(RegisterEmployeeState state) {
    return switch (state.status) {
      RegisterEmployeeStatus.success =>
        'La cuenta y el perfil se crearon correctamente.',
      RegisterEmployeeStatus.validationFailure => _validationMessage(
        state.validationError,
      ),
      RegisterEmployeeStatus.authenticationFailure => _authFailureMessage(
        state.authFailure,
      ),
      RegisterEmployeeStatus.profilePending =>
        'La cuenta pudo crearse, pero no se confirmó el perfil. No intentes '
            'registrarte de nuevo; la recuperación se implementará después.',
      RegisterEmployeeStatus.unexpectedFailure =>
        'Ocurrió un error inesperado. Inténtalo más tarde.',
      _ => null,
    };
  }

  String? _validateName(String? value) =>
      _validationMessage(AuthValidator.validateName(value));

  String? _validateEmail(String? value) =>
      _validationMessage(AuthValidator.validateEmail(value));

  String? _validatePassword(String? value) =>
      _validationMessage(AuthValidator.validatePassword(value));

  @override
  Widget build(BuildContext context) {
    final registerState = context.watch<RegisterEmployeeViewModel>().state;
    final isSubmitting =
        registerState.status == RegisterEmployeeStatus.submitting;
    final registrationFinished =
        registerState.status == RegisterEmployeeStatus.success ||
        registerState.status == RegisterEmployeeStatus.profilePending;
    final operationMessage = _operationMessage(registerState);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            enabled: !isSubmitting && !registrationFinished,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            validator: _validateName,
            onChanged: (_) => _clearFailureWhenEditing(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            enabled: !isSubmitting && !registrationFinished,
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
            enabled: !isSubmitting && !registrationFinished,
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
              if (!isSubmitting && !registrationFinished) {
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
                color: registerState.status == RegisterEmployeeStatus.success
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isSubmitting || registrationFinished ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Registrarme'),
          ),
        ],
      ),
    );
  }
}
