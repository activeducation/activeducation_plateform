import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_career.dart';
import '../../domain/usecases/get_careers_usecase.dart';

// ============================================================================
// Events
// ============================================================================

abstract class CareersEvent extends Equatable {
  const CareersEvent();
  @override
  List<Object?> get props => [];
}

class LoadCareers extends CareersEvent {
  final int page;
  final String? search;
  final String? sector;

  const LoadCareers({this.page = 1, this.search, this.sector});

  @override
  List<Object?> get props => [page, search, sector];
}

// ============================================================================
// States
// ============================================================================

abstract class CareersState extends Equatable {
  const CareersState();
  @override
  List<Object?> get props => [];
}

class CareersInitial extends CareersState {}

class CareersLoading extends CareersState {}

class CareersLoaded extends CareersState {
  final PaginatedCareers data;

  const CareersLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class CareersError extends CareersState {
  final String message;

  const CareersError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// BLoC
// ============================================================================

class CareersBloc extends Bloc<CareersEvent, CareersState> {
  final GetCareersUseCase _getCareers;

  CareersBloc(this._getCareers) : super(CareersInitial()) {
    on<LoadCareers>(_onLoadCareers);
  }

  Future<void> _onLoadCareers(
    LoadCareers event,
    Emitter<CareersState> emit,
  ) async {
    emit(CareersLoading());
    try {
      final result = await _getCareers(
        page: event.page,
        search: event.search,
        sector: event.sector,
      );
      emit(CareersLoaded(result));
    } on AdminFailure catch (e) {
      emit(CareersError(e.message));
    } catch (e) {
      emit(CareersError('Erreur inattendue : $e'));
    }
  }
}
