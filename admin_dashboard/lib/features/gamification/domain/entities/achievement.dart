import 'package:equatable/equatable.dart';

class Achievement extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int points;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.points,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, category, isActive];
}

class AdminChallenge extends Equatable {
  final String id;
  final String title;
  final String? description;
  final int targetValue;
  final int rewardPoints;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminChallenge({
    required this.id,
    required this.title,
    this.description,
    required this.targetValue,
    required this.rewardPoints,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [id, title, isActive];
}
