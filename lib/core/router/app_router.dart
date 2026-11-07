import 'package:go_router/go_router.dart';
import '../presentation/route_placeholder_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter()
    : router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(
            path: AppRoutes.root,
            redirect: (context, state) => AppRoutes.login,
          ),
          GoRoute(
            path: AppRoutes.login,
            name: AppRouteNames.login,
            builder: (context, state) =>
                const RoutePlaceholderPage(title: 'Inicio de sesion'),
          ),
          GoRoute(
            path: AppRoutes.register,
            name: AppRouteNames.register,
            builder: (context, state) =>
                const RoutePlaceholderPage(title: 'Registro'),
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
                const RoutePlaceholderPage(title: 'Mis solicitudes'),
          ),
          GoRoute(
            path: AppRoutes.supervision,
            name: AppRouteNames.supervision,
            builder: (context, state) =>
                const RoutePlaceholderPage(title: 'Bandeja de supervision'),
          ),
          GoRoute(
            path: AppRoutes.work,
            name: AppRouteNames.work,
            builder: (context, state) =>
                const RoutePlaceholderPage(title: 'Tablero de trabajo'),
          ),
        ],
      );

  final GoRouter router;
}
