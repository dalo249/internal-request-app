import 'package:flutter/material.dart';
import 'package:internal_request_app/presentation/viewmodels/register_employee_view_model.dart';
import 'package:internal_request_app/presentation/widgets/login_form.dart';
import 'package:internal_request_app/presentation/widgets/register_employee_form.dart';
import 'package:provider/provider.dart';

enum AuthPageMode { login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.initialMode});

  final AuthPageMode initialMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AuthPageMode _mode;

  bool get _isRegisterMode => _mode == AuthPageMode.register;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  void _changeMode() {
    final viewModel = context.read<RegisterEmployeeViewModel>();
    final status = viewModel.state.status;

    if (status == RegisterEmployeeStatus.submitting) return;

    if (status != RegisterEmployeeStatus.success &&
        status != RegisterEmployeeStatus.profilePending) {
      viewModel.reset();
    }

    setState(() {
      _mode = _isRegisterMode ? AuthPageMode.login : AuthPageMode.register;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        context.watch<RegisterEmployeeViewModel>().state.status ==
        RegisterEmployeeStatus.submitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_isRegisterMode)
                    const RegisterEmployeeForm()
                  else
                    const LoginForm(),
                  TextButton(
                    onPressed: isSubmitting ? null : _changeMode,
                    child: Text(
                      _isRegisterMode
                          ? 'Ya tengo una cuenta'
                          : 'Crear una cuenta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
