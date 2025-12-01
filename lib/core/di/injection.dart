import 'package:carbon_voice_console/core/di/injection.config.dart';
import 'package:carbon_voice_console/core/routing/app_router.dart';
import 'package:carbon_voice_console/core/routing/route_guard.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  getIt.init();

  // Manually register AppRouter after all dependencies are initialized
  getIt.registerSingleton<AppRouter>(AppRouter(getIt<RouteGuard>()));
}
