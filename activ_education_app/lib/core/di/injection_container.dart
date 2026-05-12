import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection_container.config.dart';
import '../auth/token_storage.dart';
import '../../features/partner/data/datasources/partner_remote_datasource.dart';
import '../../features/partner/data/repositories/partner_repository_impl.dart';
import '../../features/partner/domain/repositories/partner_repository.dart';
import '../../features/partner/presentation/bloc/partner_bloc.dart';
import '../../features/gamification/data/datasources/gamification_remote_datasource.dart';
import '../../features/gamification/data/repositories/gamification_repository.dart';

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

  // Enregistrer les dépendances Partner manuellement
  getIt.registerLazySingleton<PartnerRemoteDataSource>(
    () => PartnerRemoteDataSourceImpl(getIt<Dio>(instanceName: 'apiClient')),
  );
  getIt.registerLazySingleton<PartnerRepository>(
    () => PartnerRepositoryImpl(getIt<PartnerRemoteDataSource>()),
  );
  getIt.registerFactory<PartnerBloc>(
    () => PartnerBloc(getIt<PartnerRepository>()),
  );

  // Enregistrer les dépendances Gamification manuellement
  getIt.registerLazySingleton<GamificationRemoteDataSource>(
    () => GamificationRemoteDataSource(getIt<Dio>(instanceName: 'apiClient')),
  );
  getIt.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(getIt<GamificationRemoteDataSource>()),
  );
}
