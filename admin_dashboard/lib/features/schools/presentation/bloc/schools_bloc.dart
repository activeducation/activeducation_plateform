import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_school.dart';
import '../../domain/usecases/get_schools_usecase.dart';

// ============================================================================
// Events
// ============================================================================

abstract class SchoolsEvent extends Equatable {
  const SchoolsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSchools extends SchoolsEvent {
  final int page;
  final String? search;
  final bool? verified;

  const LoadSchools({this.page = 1, this.search, this.verified});

  @override
  List<Object?> get props => [page, search, verified];
}

// ============================================================================
// States
// ============================================================================

abstract class SchoolsState extends Equatable {
  const SchoolsState();
  @override
  List<Object?> get props => [];
}

class SchoolsInitial extends SchoolsState {}

class SchoolsLoading extends SchoolsState {}

class SchoolsLoaded extends SchoolsState {
  final PaginatedSchools data;

  const SchoolsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class SchoolsError extends SchoolsState {
  final String message;

  const SchoolsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// BLoC
// ============================================================================

class SchoolsBloc extends Bloc<SchoolsEvent, SchoolsState> {
  final GetSchoolsUseCase _getSchools;

  SchoolsBloc(this._getSchools) : super(SchoolsInitial()) {
    on<LoadSchools>(_onLoadSchools);
  }

  Future<void> _onLoadSchools(
    LoadSchools event,
    Emitter<SchoolsState> emit,
  ) async {
    emit(SchoolsLoading());
    try {
      final result = await _getSchools(
        page: event.page,
        search: event.search,
        verified: event.verified,
      );
      emit(SchoolsLoaded(result));
    } on AdminFailure catch (e) {
      emit(SchoolsError(e.message));
    } catch (e) {
      emit(SchoolsError('Erreur inattendue : $e'));
    }
  }
}
