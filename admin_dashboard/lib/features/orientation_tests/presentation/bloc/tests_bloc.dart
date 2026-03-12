import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_test.dart';
import '../../domain/usecases/get_tests_usecase.dart';

// ============================================================================
// Events
// ============================================================================

abstract class TestsEvent extends Equatable {
  const TestsEvent();
  @override
  List<Object?> get props => [];
}

class LoadTests extends TestsEvent {
  final int page;
  const LoadTests({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// ============================================================================
// States
// ============================================================================

abstract class TestsState extends Equatable {
  const TestsState();
  @override
  List<Object?> get props => [];
}

class TestsInitial extends TestsState {}

class TestsLoading extends TestsState {}

class TestsLoaded extends TestsState {
  final PaginatedTests data;

  const TestsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class TestsError extends TestsState {
  final String message;

  const TestsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// BLoC
// ============================================================================

class TestsBloc extends Bloc<TestsEvent, TestsState> {
  final GetTestsUseCase _getTests;

  TestsBloc(this._getTests) : super(TestsInitial()) {
    on<LoadTests>(_onLoadTests);
  }

  Future<void> _onLoadTests(
    LoadTests event,
    Emitter<TestsState> emit,
  ) async {
    emit(TestsLoading());
    try {
      final result = await _getTests(page: event.page);
      emit(TestsLoaded(result));
    } on AdminFailure catch (e) {
      emit(TestsError(e.message));
    } catch (e) {
      emit(TestsError('Erreur inattendue : $e'));
    }
  }
}
