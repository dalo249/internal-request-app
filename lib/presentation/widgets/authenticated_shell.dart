import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internal_request_app/core/router/app_routes.dart';
import 'package:internal_request_app/domain/enums/user_role.dart';
import 'package:internal_request_app/presentation/viewmodels/auth_gate_view_model.dart';
import 'package:provider/provider.dart';

class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthGateViewModel>().state.profile;

    // Las rutas del shell solo deberian mostrarse con sesión autenticada.
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes internas')),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(_roleName(profile.role)),
                  ],
                ),
              ),
              if (profile.role == UserRole.supervisor)
                _menuItem(
                  context,
                  icon: Icons.fact_check_outlined,
                  title: 'Bandeja de supervisión',
                  route: AppRoutes.supervision,
                ),
              if (profile.role == UserRole.executor)
                _menuItem(
                  context,
                  icon: Icons.assignment_outlined,
                  title: 'Tablero de trabajo',
                  route: AppRoutes.work,
                ),
              _menuItem(
                context,
                icon: Icons.miscellaneous_services_outlined,
                title: 'Servicios y creación',
                route: AppRoutes.services,
              ),
              _menuItem(
                context,
                icon: Icons.list_alt,
                title: 'Mis solicitudes',
                route: AppRoutes.myRequests,
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () => _signOut(context),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    Navigator.of(context).pop();
    await context.read<AuthGateViewModel>().signOut();
  }

  String _roleName(UserRole role) => switch (role) {
    UserRole.employee => 'Empleado',
    UserRole.supervisor => 'Supervisor',
    UserRole.executor => 'Ejecutor',
  };
}