import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:activ_education_app/features/elearning/presentation/bloc/course_bloc.dart';
import 'package:activ_education_app/features/elearning/presentation/pages/course_detail_page.dart';
import 'package:activ_education_app/features/elearning/domain/entities/course.dart';

// Mocks
class MockCourseBloc extends MockBloc<CourseEvent, CourseState> implements CourseBloc {}

final getIt = GetIt.instance;

void main() {
  late MockCourseBloc mockCourseBloc;

  final dummyCourseDetail = CourseDetail(
    id: 'c1',
    title: 'Test Course',
    description: 'Test description',
    category: 'tech',
    difficulty: CourseDifficulty.debutant,
    durationMinutes: 120,
    pointsReward: 50,
    isEnrolled: false,
    modules: const [
      CourseModule(
        id: 'm1',
        courseId: 'c1',
        title: 'Module 1',
        displayOrder: 1,
        isLocked: false,
        lessons: [
          LessonSummary(
            id: 'l1',
            moduleId: 'm1',
            title: 'Lesson 1',
            lessonType: LessonType.video,
            durationMinutes: 10,
            pointsReward: 10,
            isFree: true,
            status: LessonStatus.completed,
          ),
        ],
      ),
    ],
  );

  setUpAll(() {
    getIt.allowReassignment = true;
  });

  setUp(() {
    mockCourseBloc = MockCourseBloc();
    getIt.registerFactory<CourseBloc>(() => mockCourseBloc);
    
    // Default fallback state
    when(() => mockCourseBloc.state).thenReturn(CourseLoading());
  });

  tearDown(() {
    mockCourseBloc.close();
  });

  Widget buildTestApp() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CourseDetailPage(courseId: 'c1'),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('CourseDetailPage', () {
    testWidgets('affiche un shimmer (chargement) au debut', (tester) async {
      when(() => mockCourseBloc.state).thenReturn(CourseLoading());
      whenListen(
        mockCourseBloc,
        Stream.fromIterable([CourseLoading()]),
        initialState: CourseLoading(),
      );

      await tester.pumpWidget(buildTestApp());

      expect(find.text('Test Course'), findsNothing);
    });

    testWidgets('affiche les details du cours (titre, modules) une fois charge', (tester) async {
      when(() => mockCourseBloc.state).thenReturn(CourseLoaded(dummyCourseDetail));
      whenListen(
        mockCourseBloc,
        Stream.fromIterable([CourseLoaded(dummyCourseDetail)]),
        initialState: CourseLoaded(dummyCourseDetail),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Test Course'), findsOneWidget);
      expect(find.text('Module 1'), findsOneWidget);
    });

    testWidgets('affiche erreur avec bouton reessayer si erreur', (tester) async {
      when(() => mockCourseBloc.state).thenReturn(const CourseError('Erreur reseau'));
      whenListen(
        mockCourseBloc,
        Stream.fromIterable([const CourseError('Erreur reseau')]),
        initialState: const CourseError('Erreur reseau'),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Erreur reseau'), findsWidgets);
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });
}
