import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/core/providers/bloc_providers.dart';
import 'package:carbon_voice_console/core/routing/app_router.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize dependency injection
  await configureDependencies();

  // Log para debugging - verificar que la app se inicializa

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();
    return BlocProviders.generalBlocs(
      child: MaterialApp.router(
        title: 'Carbon Voice Console',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: appRouter.instance,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
