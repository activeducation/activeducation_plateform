import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection_container.config.dart';
import '../auth/token_storage.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Initialiser les dependances injectables
  await getIt.init();

  // Initialiser le TokenStorage
  final tokenStorage = getIt<TokenStorage>();
  await tokenStorage.init();
}
