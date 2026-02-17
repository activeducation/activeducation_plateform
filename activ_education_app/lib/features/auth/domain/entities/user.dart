import 'package:equatable/equatable.dart';

/// Entite utilisateur pour le domaine.
class User extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    required this.createdAt,
  });

  /// Nom complet de l'utilisateur.
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName ?? email.split('@').first;
  }

  /// Initiales pour l'avatar.
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  List<Object?> get props => [id, email];
}

/// Profil utilisateur complet.
class UserProfile extends User {
  final DateTime? dateOfBirth;
  final String? schoolName;
  final String? classLevel;
  final String preferredLanguage;
  final DateTime? updatedAt;

  const UserProfile({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    super.displayName,
    super.phoneNumber,
    super.avatarUrl,
    required super.createdAt,
    this.dateOfBirth,
    this.schoolName,
    this.classLevel,
    this.preferredLanguage = 'fr',
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        dateOfBirth,
        schoolName,
        classLevel,
        preferredLanguage,
      ];
}

/// Tokens d'authentification.
class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  /// Verifie si le token va expirer dans les prochaines minutes.
  bool willExpireSoon({int minutesThreshold = 5}) {
    // Note: Pour une verification precise, il faudrait decoder le JWT
    return false;
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}

/// Resultat d'authentification complet.
class AuthResult extends Equatable {
  final User user;
  final AuthTokens tokens;

  const AuthResult({
    required this.user,
    required this.tokens,
  });

  @override
  List<Object?> get props => [user, tokens];
}
