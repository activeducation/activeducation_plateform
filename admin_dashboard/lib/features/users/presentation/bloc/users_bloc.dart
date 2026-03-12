import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/deactivate_user_usecase.dart';

// ============================================================================
// Events
// ============================================================================

abstract class UsersEvent extends Equatable {
  const UsersEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsers extends UsersEvent {
  final int page;
  final String? search;
  final String? role;

  const LoadUsers({this.page = 1, this.search, this.role});

  @override
  List<Object?> get props => [page, search, role];
}

class DeactivateUser extends UsersEvent {
  final String userId;
  const DeactivateUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ============================================================================
// States
// ============================================================================

abstract class UsersState extends Equatable {
  const UsersState();
  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final PaginatedUsers data;

  const UsersLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class UsersError extends UsersState {
  final String message;

  const UsersError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserActionSuccess extends UsersState {
  final String message;
  const UserActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// BLoC
// ============================================================================

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final GetUsersUseCase _getUsers;
  final DeactivateUserUseCase _deactivateUser;

  UsersBloc(this._getUsers, this._deactivateUser) : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<DeactivateUser>(_onDeactivateUser);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    try {
      final result = await _getUsers(
        page: event.page,
        search: event.search,
        role: event.role,
      );
      emit(UsersLoaded(result));
    } on AdminFailure catch (e) {
      emit(UsersError(e.message));
    } catch (e) {
      emit(UsersError('Erreur inattendue : $e'));
    }
  }

  Future<void> _onDeactivateUser(
    DeactivateUser event,
    Emitter<UsersState> emit,
  ) async {
    try {
      await _deactivateUser(event.userId);
      emit(const UserActionSuccess('Utilisateur désactivé'));
      add(const LoadUsers());
    } on AdminFailure catch (e) {
      emit(UsersError(e.message));
    } catch (e) {
      emit(UsersError('Erreur inattendue : $e'));
    }
  }
}
