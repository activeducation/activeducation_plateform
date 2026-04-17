import 'package:get_it/get_it.dart';
import '../auth/token_storage.dart';
import '../network/api_client.dart';

// Dashboard
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';

// Users
import '../../features/users/data/repositories/users_repository_impl.dart';
import '../../features/users/domain/repositories/users_repository.dart';
import '../../features/users/domain/usecases/get_users_usecase.dart';
import '../../features/users/domain/usecases/deactivate_user_usecase.dart';
import '../../features/users/presentation/bloc/users_bloc.dart';

// Schools
import '../../features/schools/data/repositories/schools_repository_impl.dart';
import '../../features/schools/domain/repositories/schools_repository.dart';
import '../../features/schools/domain/usecases/get_schools_usecase.dart';
import '../../features/schools/presentation/bloc/schools_bloc.dart';

// Careers
import '../../features/careers/data/repositories/careers_repository_impl.dart';
import '../../features/careers/domain/repositories/careers_repository.dart';
import '../../features/careers/domain/usecases/get_careers_usecase.dart';
import '../../features/careers/presentation/bloc/careers_bloc.dart';

// Orientation Tests
import '../../features/orientation_tests/data/repositories/tests_repository_impl.dart';
import '../../features/orientation_tests/domain/repositories/tests_repository.dart';
import '../../features/orientation_tests/domain/usecases/get_tests_usecase.dart';
import '../../features/orientation_tests/presentation/bloc/tests_bloc.dart';

// Gamification
import '../../features/gamification/data/repositories/gamification_repository_impl.dart';
import '../../features/gamification/domain/repositories/gamification_repository.dart';
import '../../features/gamification/domain/usecases/get_achievements_usecase.dart';
import '../../features/gamification/presentation/bloc/achievements_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Core ─────────────────────────────────────────────────────────────────

  final tokenStorage = TokenStorage();
  await tokenStorage.init();
  getIt.registerSingleton<TokenStorage>(tokenStorage);

  final apiClient = ApiClient(tokenStorage);
  getIt.registerSingleton<ApiClient>(apiClient);

  // ── Dashboard ──────────────────────────────────────────────────────────────

  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt<ApiClient>()),
  );

  // ── Users ─────────────────────────────────────────────────────────────────

  getIt.registerLazySingleton<UsersRepository>(
    () => UsersRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerFactory<GetUsersUseCase>(
    () => GetUsersUseCase(getIt<UsersRepository>()),
  );
  getIt.registerFactory<DeactivateUserUseCase>(
    () => DeactivateUserUseCase(getIt<UsersRepository>()),
  );
  getIt.registerFactory<UsersBloc>(
    () => UsersBloc(getIt<GetUsersUseCase>(), getIt<DeactivateUserUseCase>()),
  );

  // ── Schools ───────────────────────────────────────────────────────────────

  getIt.registerLazySingleton<SchoolsRepository>(
    () => SchoolsRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerFactory<GetSchoolsUseCase>(
    () => GetSchoolsUseCase(getIt<SchoolsRepository>()),
  );
  getIt.registerFactory<SchoolsBloc>(
    () => SchoolsBloc(getIt<GetSchoolsUseCase>()),
  );

  // ── Careers ───────────────────────────────────────────────────────────────

  getIt.registerLazySingleton<CareersRepository>(
    () => CareersRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerFactory<GetCareersUseCase>(
    () => GetCareersUseCase(getIt<CareersRepository>()),
  );
  getIt.registerFactory<CareersBloc>(
    () => CareersBloc(getIt<GetCareersUseCase>()),
  );

  // ── Orientation Tests ─────────────────────────────────────────────────────

  getIt.registerLazySingleton<TestsRepository>(
    () => TestsRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerFactory<GetTestsUseCase>(
    () => GetTestsUseCase(getIt<TestsRepository>()),
  );
  getIt.registerFactory<TestsBloc>(() => TestsBloc(getIt<GetTestsUseCase>()));

  // ── Gamification ──────────────────────────────────────────────────────────

  getIt.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerFactory<GetAchievementsUseCase>(
    () => GetAchievementsUseCase(getIt<GamificationRepository>()),
  );
  getIt.registerFactory<GetChallengesUseCase>(
    () => GetChallengesUseCase(getIt<GamificationRepository>()),
  );
  getIt.registerFactory<AchievementsBloc>(
    () => AchievementsBloc(
      getIt<GetAchievementsUseCase>(),
      getIt<GetChallengesUseCase>(),
    ),
  );
}
