import 'package:internal_request_app/domain/enums/user_role.dart';
import 'package:internal_request_app/presentation/pages/auth_gate_page.dart';
import 'package:internal_request_app/presentation/pages/my_requests_page.dart';
import 'package:internal_request_app/presentation/pages/services_creation_page.dart';
import 'package:internal_request_app/presentation/pages/supervision_page.dart';
import 'package:internal_request_app/presentation/pages/work_board_page.dart';
import 'package:internal_request_app/presentation/widgets/authenticated_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:internal_request_app/presentation/pages/auth_page.dart';
import 'package:internal_request_app/presentation/viewmodels/auth_gate_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/area_catalog_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/create_request_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/login_user_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/my_requests_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/register_employee_view_model.dart';
import 'package:provider/provider.dart';

import '../di/dependency_injection.dart';
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
            builder: (context, state) => MultiProvider(
              providers: [
                ChangeNotifierProvider<RegisterEmployeeViewModel>(
                  create: (_) => getIt<RegisterEmployeeViewModel>(),
                ),
                ChangeNotifierProvider<LoginUserViewModel>(
                  create: (_) => getIt<LoginUserViewModel>(),
                ),
              ],
              child: const AuthPage(initialMode: AuthPageMode.login),
            ),
          ),
          GoRoute(
            path: AppRoutes.register,
            name: AppRouteNames.register,
            builder: (context, state) => MultiProvider(
              providers: [
                ChangeNotifierProvider<RegisterEmployeeViewModel>(
                  create: (_) => getIt<RegisterEmployeeViewModel>(),
                ),
                ChangeNotifierProvider<LoginUserViewModel>(
                  create: (_) => getIt<LoginUserViewModel>(),
                ),
              ],
              child: const AuthPage(initialMode: AuthPageMode.register),
            ),
          ),
          ShellRoute(
            builder: (context, state, child) =>
                AuthenticatedShell(child: child),
            routes: [
              GoRoute(
                path: AppRoutes.services,
                name: AppRouteNames.services,
                builder: (context, state) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider<AreaCatalogViewModel>(
                      create: (_) => getIt<AreaCatalogViewModel>(),
                    ),
                    ChangeNotifierProvider<CreateRequestViewModel>(
                      create: (_) => getIt<CreateRequestViewModel>(),
                    ),
                  ],
                  child: const ServicesCreationPage(),
                ),
              ),
              GoRoute(
                path: AppRoutes.myRequests,
                name: AppRouteNames.myRequests,
                builder: (context, state) =>
                    ChangeNotifierProvider<MyRequestsViewModel>(
                      create: (_) => getIt<MyRequestsViewModel>(),
                      child: const MyRequestsPage(),
                    ),
              ),
              GoRoute(
                path: AppRoutes.supervision,
                name: AppRouteNames.supervision,
                builder: (context, state) => const SupervisionPage(),
              ),
              GoRoute(
                path: AppRoutes.work,
                name: AppRouteNames.work,
                builder: (context, state) => const WorkBoardPage(),
              ),
            ],
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
    UserRole.employee => AppRoutes.services,
    UserRole.supervisor => AppRoutes.supervision,
    UserRole.executor => AppRoutes.work,
  };

  static bool _canAccessRoute(UserRole role, String location) {
    final isCommonRoute =
        location == AppRoutes.services || location == AppRoutes.myRequests;

    if (isCommonRoute) return true;

    return switch (role) {
      UserRole.employee => false,
      UserRole.supervisor => location == AppRoutes.supervision,
      UserRole.executor => location == AppRoutes.work,
    };
  }
}
