import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_dashboard/core/error/failures.dart';
import 'package:admin_dashboard/features/schools/domain/entities/admin_school.dart';
import 'package:admin_dashboard/features/schools/domain/usecases/get_schools_usecase.dart';
import 'package:admin_dashboard/features/schools/presentation/bloc/schools_bloc.dart';

class MockGetSchoolsUseCase extends Mock implements GetSchoolsUseCase {}

final tSchools = PaginatedSchools(
  items: [
    AdminSchool(
      id: 's-1',
      name: 'Lycee Kwame Nkrumah',
      city: 'Accra',
      type: 'public',
      isVerified: true,
      isActive: true,
      createdAt: DateTime(2026, 2, 1),
    ),
  ],
  total: 1,
  page: 1,
  perPage: 20,
);

void main() {
  late MockGetSchoolsUseCase getSchools;

  setUp(() {
    getSchools = MockGetSchoolsUseCase();
  });

  SchoolsBloc buildBloc() => SchoolsBloc(getSchools);

  blocTest<SchoolsBloc, SchoolsState>(
    'emet [Loading, Loaded] quand la requete reussit',
    setUp: () {
      when(() => getSchools(
            page: any(named: 'page'),
            search: any(named: 'search'),
            verified: any(named: 'verified'),
          )).thenAnswer((_) async => tSchools);
    },
    build: buildBloc,
    act: (b) => b.add(const LoadSchools()),
    expect: () => [
      isA<SchoolsLoading>(),
      SchoolsLoaded(tSchools),
    ],
  );

  blocTest<SchoolsBloc, SchoolsState>(
    'emet [Loading, Error] sur AdminFailure',
    setUp: () {
      when(() => getSchools(
            page: any(named: 'page'),
            search: any(named: 'search'),
            verified: any(named: 'verified'),
          )).thenThrow(const AdminFailure('401 Unauthorized', statusCode: 401));
    },
    build: buildBloc,
    act: (b) => b.add(const LoadSchools()),
    expect: () => [
      isA<SchoolsLoading>(),
      const SchoolsError('401 Unauthorized'),
    ],
  );

  blocTest<SchoolsBloc, SchoolsState>(
    'propage le filtre verified au use case',
    setUp: () {
      when(() => getSchools(
            page: any(named: 'page'),
            search: any(named: 'search'),
            verified: any(named: 'verified'),
          )).thenAnswer((_) async => tSchools);
    },
    build: buildBloc,
    act: (b) => b.add(const LoadSchools(page: 3, search: 'lycee', verified: false)),
    verify: (_) {
      verify(() => getSchools(page: 3, search: 'lycee', verified: false)).called(1);
    },
  );

  blocTest<SchoolsBloc, SchoolsState>(
    'emet SchoolsError generique sur exception non typee',
    setUp: () {
      when(() => getSchools(
            page: any(named: 'page'),
            search: any(named: 'search'),
            verified: any(named: 'verified'),
          )).thenThrow(Exception('network'));
    },
    build: buildBloc,
    act: (b) => b.add(const LoadSchools()),
    expect: () => [
      isA<SchoolsLoading>(),
      isA<SchoolsError>().having(
        (e) => e.message,
        'message',
        contains('Erreur inattendue'),
      ),
    ],
  );
}
