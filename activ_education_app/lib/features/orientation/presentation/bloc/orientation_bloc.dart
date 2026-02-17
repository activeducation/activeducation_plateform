import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/orientation_test.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/usecases/get_orientation_tests.dart';
import '../../domain/usecases/submit_test.dart';

// Events
abstract class OrientationEvent extends Equatable {
  const OrientationEvent();
  @override
  List<Object> get props => [];
}

class LoadOrientationTests extends OrientationEvent {}

class SubmitTestEvent extends OrientationEvent {
  final String testId;
  final Map<String, dynamic> responses;

  const SubmitTestEvent(this.testId, this.responses);

  @override
  List<Object> get props => [testId, responses];
}

class ResetOrientation extends OrientationEvent {}

// States
abstract class OrientationState extends Equatable {
  const OrientationState();
  @override
  List<Object> get props => [];
}

class OrientationInitial extends OrientationState {}

class OrientationLoading extends OrientationState {}

class OrientationTestsLoaded extends OrientationState {
  final List<OrientationTest> tests;

  const OrientationTestsLoaded(this.tests);

  @override
  List<Object> get props => [tests];
}

class TestSubmitting extends OrientationState {}

class TestCompleted extends OrientationState {
  final TestResult result;

  const TestCompleted(this.result);

  @override
  List<Object> get props => [result];
}

class OrientationError extends OrientationState {
  final String message;

  const OrientationError(this.message);

  @override
  List<Object> get props => [message];
}

@injectable
class OrientationBloc extends Bloc<OrientationEvent, OrientationState> {
  final GetOrientationTests getOrientationTests;
  final SubmitTest submitTest;

  OrientationBloc(
    this.getOrientationTests,
    this.submitTest,
  ) : super(OrientationInitial()) {
    on<LoadOrientationTests>(_onLoadTests);
    on<SubmitTestEvent>(_onSubmitTest);
     on<ResetOrientation>(_onReset);
  }

  Future<void> _onLoadTests(
    LoadOrientationTests event,
    Emitter<OrientationState> emit,
  ) async {
    emit(OrientationLoading());
    final result = await getOrientationTests();
    result.fold(
      (error) => emit(OrientationError(error.toString())),
      (tests) => emit(OrientationTestsLoaded(tests)),
    );
  }

  Future<void> _onSubmitTest(
    SubmitTestEvent event,
    Emitter<OrientationState> emit,
  ) async {
    emit(TestSubmitting());
    final result = await submitTest(event.testId, event.responses);
    result.fold(
      (error) => emit(OrientationError(error.toString())),
      (testResult) => emit(TestCompleted(testResult)),
    );
  }

  void _onReset(ResetOrientation event, Emitter<OrientationState> emit) {
    emit(OrientationInitial());
    // Auto reload tests?
    add(LoadOrientationTests());
  }
}
