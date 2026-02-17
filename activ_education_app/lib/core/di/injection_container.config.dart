// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
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
import '../../features/profile/data/repositories/profile_repository_impl.dart'
    as _i334;
import '../../features/profile/domain/repositories/profile_repository.dart'
    as _i894;
import '../../features/profile/domain/usecases/get_user_profile.dart' as _i12;
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
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i1002.TokenStorage>(() => _i1002.TokenStorage());
    gh.lazySingleton<_i894.ProfileRepository>(
        () => _i334.ProfileRepositoryImpl());
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.refreshDio,
      instanceName: 'refreshClient',
    );
    gh.lazySingleton<_i12.GetUserProfile>(
        () => _i12.GetUserProfile(gh<_i894.ProfileRepository>()));
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.apiDio(
        gh<_i1002.TokenStorage>(),
        gh<_i361.Dio>(instanceName: 'refreshClient'),
      ),
      instanceName: 'apiClient',
    );
    gh.factory<_i53.AuthInterceptor>(() => _i53.AuthInterceptor(
          gh<_i1002.TokenStorage>(),
          gh<_i361.Dio>(instanceName: 'refreshClient'),
        ));
    gh.lazySingleton<_i832.CareersRemoteDataSource>(() =>
        _i832.CareersRemoteDataSourceImpl(
            gh<_i361.Dio>(instanceName: 'apiClient')));
    gh.lazySingleton<_i107.AuthRemoteDataSource>(() =>
        _i107.AuthRemoteDataSourceImpl(
            gh<_i361.Dio>(instanceName: 'apiClient')));
    gh.lazySingleton<_i613.OrientationRemoteDataSource>(() =>
        _i613.OrientationRemoteDataSourceImpl(
            gh<_i361.Dio>(instanceName: 'apiClient')));
    gh.factory<_i469.ProfileBloc>(
        () => _i469.ProfileBloc(gh<_i12.GetUserProfile>()));
    gh.lazySingleton<_i322.OrientationRepository>(() =>
        _i759.OrientationRepositoryImpl(
            gh<_i613.OrientationRemoteDataSource>()));
    gh.lazySingleton<_i557.GetOrientationTests>(
        () => _i557.GetOrientationTests(gh<_i322.OrientationRepository>()));
    gh.lazySingleton<_i393.SubmitTest>(
        () => _i393.SubmitTest(gh<_i322.OrientationRepository>()));
    gh.lazySingleton<_i787.AuthRepository>(() => _i153.AuthRepositoryImpl(
          gh<_i107.AuthRemoteDataSource>(),
          gh<_i460.SharedPreferences>(),
          gh<_i1002.TokenStorage>(),
        ));
    gh.factory<_i535.OrientationBloc>(() => _i535.OrientationBloc(
          gh<_i557.GetOrientationTests>(),
          gh<_i393.SubmitTest>(),
        ));
    gh.factory<_i17.GetCurrentUserUseCase>(
        () => _i17.GetCurrentUserUseCase(gh<_i787.AuthRepository>()));
    gh.factory<_i188.LoginUseCase>(
        () => _i188.LoginUseCase(gh<_i787.AuthRepository>()));
    gh.factory<_i48.LogoutUseCase>(
        () => _i48.LogoutUseCase(gh<_i787.AuthRepository>()));
    gh.factory<_i941.RegisterUseCase>(
        () => _i941.RegisterUseCase(gh<_i787.AuthRepository>()));
    gh.factory<_i797.AuthBloc>(() => _i797.AuthBloc(
          gh<_i188.LoginUseCase>(),
          gh<_i941.RegisterUseCase>(),
          gh<_i48.LogoutUseCase>(),
          gh<_i17.GetCurrentUserUseCase>(),
          gh<_i787.AuthRepository>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
