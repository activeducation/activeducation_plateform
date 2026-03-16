import 'package:dartz/dartz.dart';
import '../entities/course.dart';

abstract class ElearningRepository {
  Future<Either<Exception, List<Course>>> getCourses();
  Future<Either<Exception, CourseDetail>> getCourseDetail(String id);
  Future<Either<Exception, LessonDetail>> getLesson(String id);
  Future<Either<Exception, bool>> enrollCourse(String id);
  Future<Either<Exception, List<Course>>> getMyCourses();
  Future<Either<Exception, Map<String, dynamic>>> completeLesson(
    String id, {
    int? score,
    Map<String, String>? answers,
  });
}
