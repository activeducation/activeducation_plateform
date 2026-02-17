import 'package:get_it/get_it.dart';
import '../auth/token_storage.dart';
import '../network/api_client.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Token Storage
  final tokenStorage = TokenStorage();
  await tokenStorage.init();
  getIt.registerSingleton<TokenStorage>(tokenStorage);

  // API Client
  getIt.registerSingleton<ApiClient>(ApiClient(tokenStorage));
}
