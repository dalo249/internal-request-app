import 'package:flutter/material.dart';
import 'package:internal_request_app/domain/enums/user_role.dart';
import 'package:internal_request_app/presentation/viewmodels/auth_gate_view_model.dart';
import 'package:provider/provider.dart';

class AuthenticatedHomePage extends StatefulWidget {
  const AuthenticatedHomePage({super.key, required this.role});

  final UserRole role;

  @override
  State<AuthenticatedHomePage> createState() => _AuthenticatedHomePageState();
}

class _AuthenticatedHomePageState extends State<AuthenticatedHomePage> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await context.read<AuthGateViewModel>().signOut();
    if (mounted) setState(() => _isSigningOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.role) {
      UserRole.employee => 'Mis solicitudes',
      UserRole.supervisor => 'Bandeja de supervisión',
      UserRole.executor => 'Tablero de trabajo',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _isSigningOut ? null : _signOut,
            child: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: Center(
        child: Text(
          widget.role == UserRole.employee
              ? 'Aquí aparecerán tus solicitudes.'
              : 'Esta pantalla estará disponible en una próxima etapa.',
        ),
      ),
    );
  }
}
