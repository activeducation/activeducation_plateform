import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/models/gamification_profile.dart';
import '../../data/repositories/gamification_repository.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class GamificationState extends Equatable {
  const GamificationState();

  @override
  List<Object?> get props => [];
}

class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

class GamificationLoading extends GamificationState {
  const GamificationLoading();
}

class GamificationLoaded extends GamificationState {
  final GamificationProfile profile;

  const GamificationLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class GamificationError extends GamificationState {
  final String message;

  const GamificationError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

@lazySingleton
class GamificationCubit extends Cubit<GamificationState> {
  final GamificationRepository _repository;

  GamificationCubit(this._repository) : super(const GamificationInitial());

  Future<void> load() async {
    emit(const GamificationLoading());
    try {
      final profile = await _repository.getMyProfile();
      emit(GamificationLoaded(profile));
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final profile = await _repository.getMyProfile();
      emit(GamificationLoaded(profile));
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  /// Reinitialise l'etat (a appeler au logout pour qu'un nouvel utilisateur
  /// ne voie pas brievement le XP/streak de l'ancien — le Cubit etant un
  /// singleton partage pour toute la session).
  void reset() => emit(const GamificationInitial());
}
