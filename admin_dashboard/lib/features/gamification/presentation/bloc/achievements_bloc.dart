import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/usecases/get_achievements_usecase.dart';

// ============================================================================
// Events
// ============================================================================

abstract class AchievementsEvent extends Equatable {
  const AchievementsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAchievements extends AchievementsEvent {}

class LoadChallenges extends AchievementsEvent {}

// ============================================================================
// States
// ============================================================================

abstract class AchievementsState extends Equatable {
  const AchievementsState();
  @override
  List<Object?> get props => [];
}

class AchievementsInitial extends AchievementsState {}

class AchievementsLoading extends AchievementsState {}

class AchievementsLoaded extends AchievementsState {
  final List<Achievement> achievements;

  const AchievementsLoaded(this.achievements);

  @override
  List<Object?> get props => [achievements];
}

class ChallengesLoaded extends AchievementsState {
  final List<AdminChallenge> challenges;

  const ChallengesLoaded(this.challenges);

  @override
  List<Object?> get props => [challenges];
}

class AchievementsError extends AchievementsState {
  final String message;

  const AchievementsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// BLoC
// ============================================================================

class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  final GetAchievementsUseCase _getAchievements;
  final GetChallengesUseCase _getChallenges;

  AchievementsBloc(this._getAchievements, this._getChallenges)
      : super(AchievementsInitial()) {
    on<LoadAchievements>(_onLoadAchievements);
    on<LoadChallenges>(_onLoadChallenges);
  }

  Future<void> _onLoadAchievements(
    LoadAchievements event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(AchievementsLoading());
    try {
      final result = await _getAchievements();
      emit(AchievementsLoaded(result));
    } on AdminFailure catch (e) {
      emit(AchievementsError(e.message));
    } catch (e) {
      emit(AchievementsError('Erreur inattendue : $e'));
    }
  }

  Future<void> _onLoadChallenges(
    LoadChallenges event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(AchievementsLoading());
    try {
      final result = await _getChallenges();
      emit(ChallengesLoaded(result));
    } on AdminFailure catch (e) {
      emit(AchievementsError(e.message));
    } catch (e) {
      emit(AchievementsError('Erreur inattendue : $e'));
    }
  }
}
