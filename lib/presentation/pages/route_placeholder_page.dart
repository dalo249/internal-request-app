import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';

class RoutePlaceholderPage extends StatelessWidget {
  const RoutePlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Pantalla provisional para validar las rutas.'),
          const SizedBox(height: 16),
          _RouteLink(label: 'Inicio de sesión', routeName: AppRouteNames.login),
          _RouteLink(label: 'Registro', routeName: AppRouteNames.register),
          _RouteLink(
            label: 'Servicios y creación',
            routeName: AppRouteNames.services,
          ),
          _RouteLink(
            label: 'Mis solicitudes',
            routeName: AppRouteNames.myRequests,
          ),
          _RouteLink(
            label: 'Bandeja de supervisión',
            routeName: AppRouteNames.supervision,
          ),
          _RouteLink(
            label: 'Tablero de trabajo',
            routeName: AppRouteNames.work,
          ),
        ],
      ),
    );
  }
}

class _RouteLink extends StatelessWidget {
  const _RouteLink({required this.label, required this.routeName});

  final String label;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => context.goNamed(routeName),
    );
  }
}