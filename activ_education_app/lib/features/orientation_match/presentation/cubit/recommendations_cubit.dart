import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/orientation_match_datasource.dart';
import '../../data/models/recommendation_model.dart';

// ===========================================================================
// States
// ===========================================================================

abstract class RecommendationsState extends Equatable {
  const RecommendationsState();
  @override
  List<Object?> get props => [];
}

class RecommendationsInitial extends RecommendationsState {
  const RecommendationsInitial();
}

class RecommendationsLoading extends RecommendationsState {
  const RecommendationsLoading();
}

class RecommendationsLoaded extends RecommendationsState {
  final RecommendationsResult result;
  const RecommendationsLoaded(this.result);
  @override
  List<Object?> get props => [result];
}

class RecommendationsError extends RecommendationsState {
  final String message;
  const RecommendationsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===========================================================================
// Cubit
// ===========================================================================

class RecommendationsCubit extends Cubit<RecommendationsState> {
  final OrientationMatchDataSource _dataSource;

  RecommendationsCubit(this._dataSource) : super(const RecommendationsInitial());

  Future<void> load({int limit = 10}) async {
    emit(const RecommendationsLoading());
    try {
      final result = await _dataSource.getRecommendations(limit: limit);
      emit(RecommendationsLoaded(result));
    } catch (_) {
      emit(const RecommendationsError(
        'Impossible de charger les recommandations pour le moment.',
      ));
    }
  }
}
