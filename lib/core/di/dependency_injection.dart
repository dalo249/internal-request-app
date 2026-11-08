import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../router/app_router.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies(AppConfig config) {
  getIt.registerSingleton<AppConfig>(config);

  getIt.registerSingleton<AppRouter>(
    AppRouter(),
    dispose: (appRouter) => appRouter.router.dispose(),
  );

  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
}
