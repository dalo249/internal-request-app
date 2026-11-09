import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/di/dependency_injection.dart';
import 'core/router/app_router.dart';
import 'presentation/viewmodels/auth_gate_view_model.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  final config = AppConfig.fromEnv(dotenv.env);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  configureDependencies(config);

  runApp(MyApp(router: getIt<AppRouter>().router));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: getIt<AuthGateViewModel>(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Solicitudes internas',
        theme: ThemeData(primarySwatch: Colors.blue),
        routerConfig: router,
      ),
    );
  }
}
