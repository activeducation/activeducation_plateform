import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_dashboard/core/error/failures.dart';
import 'package:admin_dashboard/features/careers/domain/entities/admin_career.dart';
import 'package:admin_dashboard/features/careers/domain/usecases/get_careers_usecase.dart';
import 'package:admin_dashboard/features/careers/presentation/bloc/careers_bloc.dart';

class MockGetCareersUseCase extends Mock implements GetCareersUseCase {}

final tCareers = PaginatedCareers(
  items: [
    AdminCareer(
      id: 'c-1',
      name: 'Developpeur logiciel',
      sector: 'Tech',
      minEducationLevel: 'Bac+3',
      isActive: true,
      createdAt: DateTime(2026, 3, 1),
    ),
  ],
  total: 1,
  page: 1,
  perPage: 20,
);

void main() {
  late MockGetCareersUseCase getCareers;

  setUp(() {
    getCareers = MockGetCareersUseCase();
  });

  CareersBloc buildBloc() => CareersBloc(getCareers);

  blocTest<CareersBloc, CareersState>(
    'emet [Loading, Loaded] quand le use case reussit',
    setUp: () {
      when(() => getCareers(
            page: any(named: 'page'),
            search: any(named: 'search'),
            sector: any(named: 'sector'),
          )).thenAnswer((_) async => tCareers);
    },
    build: buildBloc,
    act: (b) => b.add(const LoadCareers()),
    expect: () => [
      isA<CareersLoading>(),
      CareersLoaded(tCareers),
    ],
  );

  blocTest<CareersBloc, CareersState>(
    'emet CareersError sur AdminFailure',
    setUp: () {
      when(() => getCareers(
            page: any(named: 'page'),
            search: any(named: 'search'),
            sector: any(named: 'sector'),
          )).thenThrow(const AdminFailure('500 Internal'));
    },
    build: buildBloc,
    act: (b) => b.add(const LoadCareers()),
    expect: () => [
      isA<CareersLoading>(),
      const CareersError('500 Internal'),
    ],
  );

  blocTest<CareersBloc, CareersState>(
    'transmet les filtres search et sector',
    setUp: () {
      when(() => getCareers(
            page: any(named: 'page'),
            search: any(named: 'search'),
            sector: any(named: 'sector'),
          )).thenAnswer((_) async => tCareers);
    },
    build: buildBloc,
    act: (b) => b.add(const LoadCareers(page: 2, search: 'dev', sector: 'Tech')),
    verify: (_) {
      verify(() => getCareers(page: 2, search: 'dev', sector: 'Tech')).called(1);
    },
  );

  blocTest<CareersBloc, CareersState>(
    'emet CareersError generique sur exception non typee',
    setUp: () {
      when(() => getCareers(
            page: any(named: 'page'),
            search: any(named: 'search'),
            sector: any(named: 'sector'),
          )).thenThrow(Exception('timeout'));
    },
    build: buildBloc,
    act: (b) => b.add(const LoadCareers()),
    expect: () => [
      isA<CareersLoading>(),
      isA<CareersError>().having(
        (e) => e.message,
        'message',
        contains('Erreur inattendue'),
      ),
    ],
  );
}
