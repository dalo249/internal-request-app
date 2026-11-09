import 'package:internal_request_app/domain/enums/user_role.dart';
import 'package:internal_request_app/presentation/pages/auth_gate_page.dart';
import 'package:internal_request_app/presentation/pages/authenticated_home_page.dart';
import 'package:go_router/go_router.dart';
import 'package:internal_request_app/presentation/pages/auth_page.dart';
import 'package:internal_request_app/presentation/viewmodels/auth_gate_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/register_employee_view_model.dart';
import 'package:provider/provider.dart';

import '../di/dependency_injection.dart';
import '../../presentation/pages/route_placeholder_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter(AuthGateViewModel authGateViewModel)
    : router = GoRouter(
        initialLocation: AppRoutes.root,
        refreshListenable: authGateViewModel,
        redirect: (context, state) =>
            _redirect(authGateViewModel, state.matchedLocation),
        routes: [
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) => const AuthGatePage(),
          ),
          GoRoute(
            path: AppRoutes.login,
            name: AppRouteNames.login,
            builder: (context, state) => ChangeNotifierProvider(
              create: (_) => getIt<RegisterEmployeeViewModel>(),
              child: const AuthPage(initialMode: AuthPageMode.login),
            ),
          ),
          GoRoute(
            path: AppRoutes.register,
            name: AppRouteNames.register,
            builder: (context, state) => ChangeNotifierProvider(
              create: (_) => getIt<RegisterEmployeeViewModel>(),
              child: const AuthPage(initialMode: AuthPageMode.register),
            ),
          ),
          GoRoute(
            path: AppRoutes.services,
            name: AppRouteNames.services,
            builder: (context, state) =>
                const RoutePlaceholderPage(title: 'Servicios y creacion'),
          ),
          GoRoute(
            path: AppRoutes.myRequests,
            name: AppRouteNames.myRequests,
            builder: (context, state) =>
                const AuthenticatedHomePage(role: UserRole.employee),
          ),
          GoRoute(
            path: AppRoutes.supervision,
            name: AppRouteNames.supervision,
            builder: (context, state) =>
                const AuthenticatedHomePage(role: UserRole.supervisor),
          ),
          GoRoute(
            path: AppRoutes.work,
            name: AppRouteNames.work,
            builder: (context, state) =>
                const AuthenticatedHomePage(role: UserRole.executor),
          ),
        ],
      );

  final GoRouter router;

  static String? _redirect(AuthGateViewModel gate, String location) {
    final status = gate.state.status;
    final isAuthLocation =
        location == AppRoutes.login || location == AppRoutes.register;

    switch (status) {
      case AuthGateStatus.checkingSession:
      case AuthGateStatus.loadingProfile:
      case AuthGateStatus.waitingForProfile:
      case AuthGateStatus.profileFailure:
      case AuthGateStatus.sessionFailure:
      case AuthGateStatus.signingOut:
        return location == AppRoutes.root ? null : AppRoutes.root;
      case AuthGateStatus.signedOut:
        return isAuthLocation ? null : AppRoutes.login;
      case AuthGateStatus.authenticated:
        final role = gate.state.profile!.role;
        final homeRoute = _homeRoute(role);

        if (location == AppRoutes.root || isAuthLocation) {
          return homeRoute;
        }

        if (_canAccessRoute(role, location)) return null;
        return homeRoute;
    }
  }

  static String _homeRoute(UserRole role) => switch (role) {
    UserRole.employee => AppRoutes.myRequests,
    UserRole.supervisor => AppRoutes.supervision,
    UserRole.executor => AppRoutes.work,
  };

  static bool _canAccessRoute(UserRole role, String location) => switch (role) {
    UserRole.employee =>
      location == AppRoutes.myRequests || location == AppRoutes.services,
    UserRole.supervisor => location == AppRoutes.supervision,
    UserRole.executor => location == AppRoutes.work,
  };
}
