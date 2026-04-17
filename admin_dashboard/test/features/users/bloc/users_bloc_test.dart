import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_dashboard/core/error/failures.dart';
import 'package:admin_dashboard/features/users/domain/entities/admin_user.dart';
import 'package:admin_dashboard/features/users/domain/usecases/deactivate_user_usecase.dart';
import 'package:admin_dashboard/features/users/domain/usecases/get_users_usecase.dart';
import 'package:admin_dashboard/features/users/presentation/bloc/users_bloc.dart';

class MockGetUsersUseCase extends Mock implements GetUsersUseCase {}

class MockDeactivateUserUseCase extends Mock implements DeactivateUserUseCase {}

final tUsers = PaginatedUsers(
  items: [
    AdminUser(
      id: 'u-1',
      email: 'a@example.com',
      role: 'student',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ],
  total: 1,
  page: 1,
  perPage: 20,
);

void main() {
  late MockGetUsersUseCase getUsers;
  late MockDeactivateUserUseCase deactivateUser;

  setUp(() {
    getUsers = MockGetUsersUseCase();
    deactivateUser = MockDeactivateUserUseCase();
  });

  UsersBloc buildBloc() => UsersBloc(getUsers, deactivateUser);

  group('LoadUsers', () {
    blocTest<UsersBloc, UsersState>(
      'emet [Loading, Loaded] quand le use case reussit',
      setUp: () {
        when(() => getUsers(
              page: any(named: 'page'),
              search: any(named: 'search'),
              role: any(named: 'role'),
            )).thenAnswer((_) async => tUsers);
      },
      build: buildBloc,
      act: (b) => b.add(const LoadUsers()),
      expect: () => [
        isA<UsersLoading>(),
        UsersLoaded(tUsers),
      ],
    );

    blocTest<UsersBloc, UsersState>(
      'emet [Loading, Error] sur AdminFailure',
      setUp: () {
        when(() => getUsers(
              page: any(named: 'page'),
              search: any(named: 'search'),
              role: any(named: 'role'),
            )).thenThrow(const AdminFailure('403 Forbidden', statusCode: 403));
      },
      build: buildBloc,
      act: (b) => b.add(const LoadUsers()),
      expect: () => [
        isA<UsersLoading>(),
        const UsersError('403 Forbidden'),
      ],
    );

    blocTest<UsersBloc, UsersState>(
      'emet [Loading, Error] sur exception inattendue',
      setUp: () {
        when(() => getUsers(
              page: any(named: 'page'),
              search: any(named: 'search'),
              role: any(named: 'role'),
            )).thenThrow(StateError('boom'));
      },
      build: buildBloc,
      act: (b) => b.add(const LoadUsers()),
      expect: () => [
        isA<UsersLoading>(),
        isA<UsersError>().having(
          (e) => e.message,
          'message',
          contains('Erreur inattendue'),
        ),
      ],
    );

    blocTest<UsersBloc, UsersState>(
      'passe search et role au use case',
      setUp: () {
        when(() => getUsers(
              page: any(named: 'page'),
              search: any(named: 'search'),
              role: any(named: 'role'),
            )).thenAnswer((_) async => tUsers);
      },
      build: buildBloc,
      act: (b) => b.add(const LoadUsers(page: 2, search: 'kofi', role: 'teacher')),
      verify: (_) {
        verify(() => getUsers(page: 2, search: 'kofi', role: 'teacher')).called(1);
      },
    );
  });

  group('DeactivateUser', () {
    blocTest<UsersBloc, UsersState>(
      'emet UserActionSuccess puis recharge la liste',
      setUp: () {
        when(() => deactivateUser(any())).thenAnswer((_) async {});
        when(() => getUsers(
              page: any(named: 'page'),
              search: any(named: 'search'),
              role: any(named: 'role'),
            )).thenAnswer((_) async => tUsers);
      },
      build: buildBloc,
      act: (b) => b.add(const DeactivateUser('u-1')),
      expect: () => [
        isA<UserActionSuccess>(),
        isA<UsersLoading>(),
        isA<UsersLoaded>(),
      ],
      verify: (_) {
        verify(() => deactivateUser('u-1')).called(1);
      },
    );

    blocTest<UsersBloc, UsersState>(
      'emet UsersError si la desactivation echoue',
      setUp: () {
        when(() => deactivateUser(any()))
            .thenThrow(const AdminFailure('Echec desactivation'));
      },
      build: buildBloc,
      act: (b) => b.add(const DeactivateUser('u-1')),
      expect: () => [
        const UsersError('Echec desactivation'),
      ],
    );
  });
}
