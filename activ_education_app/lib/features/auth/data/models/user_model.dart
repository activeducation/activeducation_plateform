import '../../domain/entities/user.dart';

/// Modele User pour la serialisation JSON.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    super.displayName,
    super.phoneNumber,
    super.avatarUrl,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      displayName: json['display_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User toEntity() => User(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );
}

/// Modele UserProfile pour la serialisation JSON.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    super.displayName,
    super.phoneNumber,
    super.avatarUrl,
    required super.createdAt,
    super.dateOfBirth,
    super.schoolName,
    super.classLevel,
    super.preferredLanguage = 'fr',
    super.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      displayName: json['display_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      schoolName: json['school_name'] as String?,
      classLevel: json['class_level'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'fr',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'school_name': schoolName,
      'class_level': classLevel,
      'preferred_language': preferredLanguage,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile toEntity() => UserProfile(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
        dateOfBirth: dateOfBirth,
        schoolName: schoolName,
        classLevel: classLevel,
        preferredLanguage: preferredLanguage,
        updatedAt: updatedAt,
      );
}

/// Modele AuthTokens pour la serialisation JSON.
class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresIn,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
    };
  }

  AuthTokens toEntity() => AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
      );
}

/// Modele AuthResult pour la serialisation JSON.
class AuthResultModel {
  final UserModel user;
  final AuthTokensModel tokens;

  const AuthResultModel({
    required this.user,
    required this.tokens,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    return AuthResultModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokensModel.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }

  AuthResult toEntity() => AuthResult(
        user: user.toEntity(),
        tokens: tokens.toEntity(),
      );
}
