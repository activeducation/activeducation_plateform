import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../core/auth/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SharedPreferences _prefs;
  final TokenStorage _tokenStorage;

  // Cle pour le cache utilisateur
  static const _userKey = 'cached_user';

  AuthRepositoryImpl(this._remoteDataSource, this._prefs, this._tokenStorage);

  @override
  Future<Either<AuthFailure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.login(email, password);

      // Sauvegarder les tokens et l'utilisateur
      await _saveTokens(result.tokens);
      await _saveUser(result.user);

      return Right(result.toEntity());
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e));
    }
  }

  @override
  Future<Either<AuthFailure, AuthResult>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final result = await _remoteDataSource.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      // Sauvegarder les tokens et l'utilisateur
      await _saveTokens(result.tokens);
      await _saveUser(result.user);

      return Right(result.toEntity());
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Ignorer les erreurs de logout cote serveur
    }

    // Toujours nettoyer le stockage local
    await _clearStorage();

    return const Right(null);
  }

  @override
  Future<Either<AuthFailure, AuthTokens>> refreshTokens() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return Left(AuthFailure.tokenExpired());
      }

      final tokens = await _remoteDataSource.refreshTokens(refreshToken);

      // Sauvegarder les nouveaux tokens
      await _saveTokens(tokens);

      return Right(tokens.toEntity());
    } on AuthException catch (e) {
      if (e.type == AuthExceptionType.unauthorized) {
        await _clearStorage();
        return Left(AuthFailure.tokenExpired());
      }
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> forgotPassword(String email) async {
    try {
      await _remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(token, newPassword);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(currentPassword, newPassword);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e));
    }
  }

  @override
  Future<Either<AuthFailure, UserProfile>> getCurrentUserProfile() async {
    try {
      final profile = await _remoteDataSource.getCurrentUserProfile();
      await _saveUser(UserModel(
        id: profile.id,
        email: profile.email,
        firstName: profile.firstName,
        lastName: profile.lastName,
        displayName: profile.displayName,
        phoneNumber: profile.phoneNumber,
        avatarUrl: profile.avatarUrl,
        createdAt: profile.createdAt,
      ));
      return Right(profile.toEntity());
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e));
    }
  }

  @override
  Future<Either<AuthFailure, UserProfile>> updateProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? schoolName,
    String? classLevel,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (displayName != null) data['display_name'] = displayName;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth.toIso8601String();
      if (schoolName != null) data['school_name'] = schoolName;
      if (classLevel != null) data['class_level'] = classLevel;

      final profile = await _remoteDataSource.updateProfile(data);
      return Right(profile.toEntity());
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasValidTokens();
  }

  @override
  Future<User?> getCachedUser() async {
    final userJson = _prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap).toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthTokens?> getStoredTokens() async {
    final accessToken = await _tokenStorage.getAccessToken();
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (accessToken == null || refreshToken == null) return null;

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: 0, // Non stocke localement
    );
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  Future<void> _saveTokens(AuthTokensModel tokens) async {
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<void> _saveUser(UserModel user) async {
    await _prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<void> _clearStorage() async {
    await _tokenStorage.clearTokens();
    await _prefs.remove(_userKey);
  }

  AuthFailure _mapAuthException(AuthException e) {
    switch (e.type) {
      case AuthExceptionType.unauthorized:
        return AuthFailure.invalidCredentials();
      case AuthExceptionType.forbidden:
        return AuthFailure.unauthorized();
      case AuthExceptionType.conflict:
        return AuthFailure.emailAlreadyExists();
      case AuthExceptionType.validation:
        return AuthFailure.weakPassword();
      case AuthExceptionType.network:
      case AuthExceptionType.timeout:
        return AuthFailure.networkError();
      case AuthExceptionType.server:
        return AuthFailure.serverError(e.message);
      default:
        return AuthFailure.unknown(e);
    }
  }
}
