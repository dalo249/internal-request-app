import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internal_request_app/data/datasources/area_remote_data_source.dart';
import 'package:internal_request_app/data/datasources/request_local_data_source.dart';
import 'package:internal_request_app/data/datasources/request_remote_data_source.dart';
import 'package:internal_request_app/data/datasources/auth_remote_datasource.dart';
import 'package:internal_request_app/data/datasources/user_profile_remote_datasource.dart';
import 'package:internal_request_app/data/local/app_database.dart';
import 'package:internal_request_app/data/repositories/area_repository_impl.dart';
import 'package:internal_request_app/data/repositories/request_repository_impl.dart';
import 'package:internal_request_app/data/repositories/auth_repository_impl.dart';
import 'package:internal_request_app/domain/repositories/area_repository.dart';
import 'package:internal_request_app/domain/repositories/request_repository.dart';
import 'package:internal_request_app/domain/repositories/auth_repository.dart';
import 'package:internal_request_app/domain/usecases/get_areas.dart';
import 'package:internal_request_app/domain/usecases/create_request.dart';
import 'package:internal_request_app/domain/usecases/login_user.dart';
import 'package:internal_request_app/domain/usecases/register_employee.dart';
import 'package:internal_request_app/presentation/viewmodels/area_catalog_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/create_request_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/register_employee_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/auth_gate_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/login_user_view_model.dart';

import '../config/app_config.dart';
import '../router/app_router.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies(AppConfig config) {
  getIt.registerSingleton<AppConfig>(config);

  // Request (persistencia local con drift)
  getIt.registerLazySingleton<AppDatabase>(
    AppDatabase.new,
    dispose: (database) => database.close(),
  );
  getIt.registerLazySingleton<RequestLocalDataSource>(
    () => RequestLocalDataSource(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<RequestRemoteDataSource>(
    () => RequestRemoteDataSource(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<RequestRepository>(
    () => RequestRepositoryImpl(
      getIt<RequestLocalDataSource>(),
      getIt<RequestRemoteDataSource>(),
      getIt<UserProfileRemoteDataSource>(),
    ),
  );
  getIt.registerFactory<CreateRequest>(
    () => CreateRequest(getIt<RequestRepository>()),
  );
  getIt.registerFactory<CreateRequestViewModel>(
    () => CreateRequestViewModel(getIt<CreateRequest>()),
  );

  //Areas y services
  getIt.registerLazySingleton<http.Client>(
    http.Client.new,
    dispose: (client) => client.close(),
  );

  getIt.registerLazySingleton<AreaRemoteDataSource>(
    () => AreaRemoteDataSource(
      client: getIt<http.Client>(),
      apiBaseUrl: getIt<AppConfig>().apiBaseUrl,
    ),
  );
  getIt.registerLazySingleton<AreaRepository>(
    () => AreaRepositoryImpl(getIt<AreaRemoteDataSource>()),
  );
  getIt.registerFactory<GetAreas>(() => GetAreas(getIt<AreaRepository>()));

  getIt.registerFactory<AreaCatalogViewModel>(
    () => AreaCatalogViewModel(getIt<GetAreas>()),
  );

  //Auth
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(firebaseAuth: getIt<FirebaseAuth>()),
  );

  getIt.registerLazySingleton<UserProfileRemoteDataSource>(
    () => UserProfileRemoteDataSource(getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<UserProfileRemoteDataSource>(),
    ),
  );

  getIt.registerFactory<RegisterEmployee>(
    () => RegisterEmployee(getIt<AuthRepository>()),
  );

  getIt.registerFactory<LoginUser>(() => LoginUser(getIt<AuthRepository>()));

  getIt.registerFactory<RegisterEmployeeViewModel>(
    () => RegisterEmployeeViewModel(getIt<RegisterEmployee>()),
  );

  getIt.registerFactory<LoginUserViewModel>(
    () => LoginUserViewModel(getIt<LoginUser>()),
  );

  getIt.registerLazySingleton<AuthGateViewModel>(
    () => AuthGateViewModel(getIt<AuthRepository>()),
    dispose: (viewModel) => viewModel.dispose(),
  );

  getIt.registerSingleton<AppRouter>(
    AppRouter(getIt<AuthGateViewModel>()),
    dispose: (appRouter) => appRouter.router.dispose(),
  );
}
