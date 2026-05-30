// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i107;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/get_current_user_usecase.dart'
    as _i17;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/domain/usecases/logout_usecase.dart' as _i48;
import '../../features/auth/domain/usecases/register_usecase.dart' as _i941;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/elearning/data/datasources/elearning_remote_datasource.dart'
    as _i396;
import '../../features/elearning/data/repositories/elearning_repository_impl.dart'
    as _i263;
import '../../features/elearning/domain/repositories/elearning_repository.dart'
    as _i62;
import '../../features/elearning/domain/usecases/complete_lesson_usecase.dart'
    as _i355;
import '../../features/elearning/domain/usecases/enroll_course_usecase.dart'
    as _i167;
import '../../features/elearning/domain/usecases/get_course_detail_usecase.dart'
    as _i8;
import '../../features/elearning/domain/usecases/get_courses_usecase.dart'
    as _i302;
import '../../features/elearning/domain/usecases/get_lesson_usecase.dart'
    as _i194;
import '../../features/elearning/domain/usecases/get_my_courses_usecase.dart'
    as _i865;
import '../../features/elearning/presentation/bloc/catalog_bloc.dart' as _i278;
import '../../features/elearning/presentation/bloc/course_bloc.dart' as _i966;
import '../../features/elearning/presentation/bloc/lesson_bloc.dart' as _i887;
import '../../features/gamification/data/datasources/gamification_remote_datasource.dart'
    as _i788;
import '../../features/gamification/data/repositories/gamification_repository.dart'
    as _i493;
import '../../features/orientation/data/datasources/careers_remote_data_source.dart'
    as _i832;
import '../../features/orientation/data/datasources/orientation_remote_data_source.dart'
    as _i613;
import '../../features/orientation/data/repositories/orientation_repository_impl.dart'
    as _i759;
import '../../features/orientation/domain/repositories/orientation_repository.dart'
    as _i322;
import '../../features/orientation/domain/usecases/get_orientation_tests.dart'
    as _i557;
import '../../features/orientation/domain/usecases/submit_test.dart' as _i393;
import '../../features/orientation/presentation/bloc/orientation_bloc.dart'
    as _i535;
import '../../features/partner/data/datasources/partner_remote_datasource.dart'
    as _i101;
import '../../features/partner/data/repositories/partner_repository_impl.dart'
    as _i57;
import '../../features/partner/domain/repositories/partner_repository.dart'
    as _i1042;
import '../../features/partner/presentation/bloc/partner_bloc.dart' as _i12;
import '../../features/profile/data/repositories/profile_repository_impl.dart'
    as _i334;
import '../../features/profile/domain/repositories/profile_repository.dart'
    as _i894;
import '../../features/profile/domain/usecases/get_user_profile_usecase.dart'
    as _i146;
import '../../features/profile/presentation/bloc/profile_bloc.dart' as _i469;
import '../auth/auth_interceptor.dart' as _i53;
import '../auth/token_storage.dart' as _i1002;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i894.ProfileRepository>(
      () => _i334.ProfileRepositoryImpl(),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.refreshDio,
      instanceName: 'refreshClient',
    );
    gh.lazySingleton<_i146.GetUserProfile>(
      () => _i146.GetUserProfile(gh<_i894.ProfileRepository>()),
    );
    gh.lazySingleton<_i1002.TokenStorage>(
      () =>
          _i1002.TokenStorage(secureStorage: gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.apiDio(
        gh<_i1002.TokenStorage>(),
        gh<_i361.Dio>(instanceName: 'refreshClient'),
      ),
      instanceName: 'apiClient',
    );
    gh.factory<_i53.AuthInterceptor>(
      () => _i53.AuthInterceptor(
        gh<_i1002.TokenStorage>(),
        gh<_i361.Dio>(instanceName: 'refreshClient'),
      ),
    );
    gh.lazySingleton<_i832.CareersRemoteDataSource>(
      () => _i832.CareersRemoteDataSourceImpl(
        gh<_i361.Dio>(instanceName: 'apiClient'),
      ),
    );
    gh.factory<_i469.ProfileBloc>(
      () => _i469.ProfileBloc(gh<_i146.GetUserProfile>()),
    );
    gh.lazySingleton<_i101.PartnerRemoteDataSource>(
      () => _i101.PartnerRemoteDataSourceImpl(
        gh<_i361.Dio>(instanceName: 'apiClient'),
      ),
    );
    gh.lazySingleton<_i107.AuthRemoteDataSource>(
      () => _i107.AuthRemoteDataSourceImpl(
        gh<_i361.Dio>(instanceName: 'apiClient'),
      ),
    );
    gh.lazySingleton<_i396.ElearningRemoteDataSource>(
      () => _i396.ElearningRemoteDataSourceImpl(
        gh<_i361.Dio>(instanceName: 'apiClient'),
      ),
    );
    gh.lazySingleton<_i613.OrientationRemoteDataSource>(
      () => _i613.OrientationRemoteDataSourceImpl(
        gh<_i361.Dio>(instanceName: 'apiClient'),
      ),
    );
    gh.lazySingleton<_i788.GamificationRemoteDataSource>(
      () => _i788.GamificationRemoteDataSource(
        gh<_i361.Dio>(instanceName: 'apiClient'),
      ),
    );
    gh.lazySingleton<_i493.GamificationRepository>(
      () => _i493.GamificationRepositoryImpl(
        gh<_i788.GamificationRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i322.OrientationRepository>(
      () => _i759.OrientationRepositoryImpl(
        gh<_i613.OrientationRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i62.ElearningRepository>(
      () =>
          _i263.ElearningRepositoryImpl(gh<_i396.ElearningRemoteDataSource>()),
    );
    gh.lazySingleton<_i557.GetOrientationTests>(
      () => _i557.GetOrientationTests(gh<_i322.OrientationRepository>()),
    );
    gh.lazySingleton<_i393.SubmitTest>(
      () => _i393.SubmitTest(gh<_i322.OrientationRepository>()),
    );
    gh.lazySingleton<_i1042.PartnerRepository>(
      () => _i57.PartnerRepositoryImpl(gh<_i101.PartnerRemoteDataSource>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(
        gh<_i107.AuthRemoteDataSource>(),
        gh<_i460.SharedPreferences>(),
        gh<_i1002.TokenStorage>(),
      ),
    );
    gh.factory<_i535.OrientationBloc>(
      () => _i535.OrientationBloc(
        gh<_i557.GetOrientationTests>(),
        gh<_i393.SubmitTest>(),
      ),
    );
    gh.factory<_i17.GetCurrentUserUseCase>(
      () => _i17.GetCurrentUserUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i188.LoginUseCase>(
      () => _i188.LoginUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i48.LogoutUseCase>(
      () => _i48.LogoutUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i941.RegisterUseCase>(
      () => _i941.RegisterUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i355.CompleteLessonUsecase>(
      () => _i355.CompleteLessonUsecase(gh<_i62.ElearningRepository>()),
    );
    gh.lazySingleton<_i167.EnrollCourseUsecase>(
      () => _i167.EnrollCourseUsecase(gh<_i62.ElearningRepository>()),
    );
    gh.lazySingleton<_i8.GetCourseDetailUsecase>(
      () => _i8.GetCourseDetailUsecase(gh<_i62.ElearningRepository>()),
    );
    gh.lazySingleton<_i302.GetCoursesUsecase>(
      () => _i302.GetCoursesUsecase(gh<_i62.ElearningRepository>()),
    );
    gh.lazySingleton<_i194.GetLessonUsecase>(
      () => _i194.GetLessonUsecase(gh<_i62.ElearningRepository>()),
    );
    gh.lazySingleton<_i865.GetMyCoursesUsecase>(
      () => _i865.GetMyCoursesUsecase(gh<_i62.ElearningRepository>()),
    );
    gh.factory<_i966.CourseBloc>(
      () => _i966.CourseBloc(
        gh<_i8.GetCourseDetailUsecase>(),
        gh<_i167.EnrollCourseUsecase>(),
      ),
    );
    gh.factory<_i887.LessonBloc>(
      () => _i887.LessonBloc(
        gh<_i194.GetLessonUsecase>(),
        gh<_i355.CompleteLessonUsecase>(),
      ),
    );
    gh.factory<_i797.AuthBloc>(
      () => _i797.AuthBloc(
        gh<_i188.LoginUseCase>(),
        gh<_i941.RegisterUseCase>(),
        gh<_i48.LogoutUseCase>(),
        gh<_i17.GetCurrentUserUseCase>(),
        gh<_i787.AuthRepository>(),
      ),
    );
    gh.factory<_i12.PartnerBloc>(
      () => _i12.PartnerBloc(gh<_i1042.PartnerRepository>()),
    );
    gh.factory<_i278.CatalogBloc>(
      () => _i278.CatalogBloc(
        gh<_i302.GetCoursesUsecase>(),
        gh<_i865.GetMyCoursesUsecase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
