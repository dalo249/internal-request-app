import 'package:flutter/material.dart';
import 'package:internal_request_app/domain/errors/profile_load_failure_exception.dart';
import 'package:internal_request_app/presentation/viewmodels/auth_gate_view_model.dart';
import 'package:provider/provider.dart';

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthGateViewModel>().state;

    return switch (state.status) {
      AuthGateStatus.checkingSession ||
      AuthGateStatus.loadingProfile ||
      AuthGateStatus.signingOut => const _LoadingPage(),
      AuthGateStatus.waitingForProfile => const _WaitingProfilePage(),
      AuthGateStatus.signedOut => const _MessagePage(
        message: 'Redirigiendo al inicio de sesión.',
      ),
      AuthGateStatus.authenticated => const _MessagePage(
        message: 'Redirigiendo a tu pantalla principal.',
      ),
      AuthGateStatus.profileFailure => _FailurePage(
        message: _profileFailureMessage(state.profileFailure),
      ),
      AuthGateStatus.sessionFailure => const _FailurePage(
        message: 'No fue posible comprobar la sesión. Inténtalo nuevamente.',
      ),
    };
  }

  String _profileFailureMessage(
    ProfileLoadFailure? failure,
  ) => switch (failure) {
    ProfileLoadFailure.permissionDenied =>
      'No tienes permiso para leer tu perfil. Contacta con el administrador.',
    ProfileLoadFailure.unavailable =>
      'No se pudo conectar con el servicio. Revisa tu conexión.',
    ProfileLoadFailure.invalidData =>
      'Los datos del perfil no son válidos. Contacta con el administrador.',
    ProfileLoadFailure.unknown =>
      'No fue posible cargar el perfil. Inténtalo nuevamente.',
    null => 'No fue posible cargar el perfil. Inténtalo nuevamente.',
  };
}

class _WaitingProfilePage extends StatelessWidget {
  const _WaitingProfilePage();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AuthGateViewModel>();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'La sesión está activa. Esperando que el perfil esté '
                'disponible...',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: viewModel.retry,
                child: const Text('Volver a consultar'),
              ),
              TextButton(
                onPressed: viewModel.signOut,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _MessagePage extends StatelessWidget {
  const _MessagePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}

class _FailurePage extends StatelessWidget {
  const _FailurePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AuthGateViewModel>();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: viewModel.retry,
                child: const Text('Reintentar'),
              ),
              TextButton(
                onPressed: viewModel.signOut,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
