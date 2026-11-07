import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'app/router/app_router.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  final config = AppConfig.fromEnv(dotenv.env);

  final appRouter = AppRouter();
  runApp(MyApp(config: config, router: appRouter.router));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.config, required this.router});

  final AppConfig config;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Solicitudes internas',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: router,
    );
  }
}
