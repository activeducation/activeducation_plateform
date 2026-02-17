import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final int level;
  final int xp;
  final int currentStreak;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.level,
    required this.xp,
    required this.currentStreak,
  });

  @override
  List<Object?> get props => [id, fullName, email, avatarUrl, level, xp, currentStreak];
}
