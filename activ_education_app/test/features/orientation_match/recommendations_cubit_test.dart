import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:activ_education_app/features/orientation_match/data/datasources/orientation_match_datasource.dart';
import 'package:activ_education_app/features/orientation_match/data/models/recommendation_model.dart';
import 'package:activ_education_app/features/orientation_match/presentation/cubit/recommendations_cubit.dart';

class MockDataSource extends Mock implements OrientationMatchDataSource {}

void main() {
  late MockDataSource ds;

  setUp(() => ds = MockDataSource());

  const _result = RecommendationsResult(
    recommendations: [
      CareerRecommendation(careerName: 'Développeur', score: 80),
    ],
    hasTestResult: true,
    completeness: ProfileCompleteness(percent: 60, missing: ['votre budget']),
  );

  blocTest<RecommendationsCubit, RecommendationsState>(
    'load succès → [Loading, Loaded]',
    build: () {
      when(() => ds.getRecommendations(limit: any(named: 'limit')))
          .thenAnswer((_) async => _result);
      return RecommendationsCubit(ds);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<RecommendationsLoading>(),
      isA<RecommendationsLoaded>(),
    ],
  );

  blocTest<RecommendationsCubit, RecommendationsState>(
    'load échec → [Loading, Error]',
    build: () {
      when(() => ds.getRecommendations(limit: any(named: 'limit')))
          .thenThrow(Exception('réseau'));
      return RecommendationsCubit(ds);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<RecommendationsLoading>(),
      isA<RecommendationsError>(),
    ],
  );
}
