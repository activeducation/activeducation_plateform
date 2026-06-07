import 'package:flutter/foundation.dart';

/// Endpoints API pour le backend FastAPI.
///
/// L'URL du backend est configurable via --dart-define=API_BASE_URL=...
/// Exemple build web production:
///   flutter build web --dart-define=API_BASE_URL=https://mon-backend.onrender.com
class ApiEndpoints {
  ApiEndpoints._();

  // ============================================
  // BASE URL
  // ============================================

  /// URL du backend injectee au build via --dart-define=API_BASE_URL=...
  /// Fallback: detection automatique selon la plateforme.
  static final String baseUrl = _resolveBaseUrl();

  /// Prefixe commun de toutes les routes backend.
  static const String apiV1 = '/api/v1';

  static String _resolveBaseUrl() {
    // 1. Verifier si une URL a ete injectee au build
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // 2. Fallback dev: detection plateforme
    const port = '8000';
    if (kIsWeb) {
      return 'http://localhost:$port';
    }
    // Android emulateur: 10.0.2.2 = localhost de la machine hote
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://localhost:$port';
  }

  // ============================================
  // AUTHENTIFICATION
  // ============================================
  static const String auth = '$apiV1/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';

  // ============================================
  // UTILISATEURS
  // ============================================
  static const String users = '$apiV1/users';
  static const String userProfile = '$users/me';
  static const String updateProfile = '$users/me';
  static const String uploadAvatar = '$users/me/avatar';

  // ============================================
  // ORIENTATION
  // ============================================
  static const String orientation = '$apiV1/orientation';
  static const String tests = '$orientation/tests';
  static String testById(String id) => '$tests/$id';
  static String startTest(String id) => '$tests/$id/start';
  static const String sessions = '$orientation/sessions';
  static String sessionById(String id) => '$sessions/$id';
  static String submitSession(String id) => '$sessions/$id/submit';
  static String sessionResults(String id) => '$sessions/$id/results';
  static const String recommendations = '$orientation/recommendations';

  // ============================================
  // CARRIERES
  // ============================================
  static const String careers = '$orientation/mobile/careers';
  static String careerById(String id) => '$careers/$id';

  // ============================================
  // MENTORS
  // ============================================
  static const String mentors = '$apiV1/mentors';
  static String mentorById(String id) => '$mentors/$id';
  static String mentorReviews(String id) => '$mentors/$id/reviews';
  static String requestMentor(String id) => '$mentors/$id/request';
  static const String mentorApply = '$mentors/apply';
  static const String mentorRelationships = '$apiV1/mentor-relationships';
  static String relationshipById(String id) => '$mentorRelationships/$id';
  static const String mentorList = '$apiV1/mentors';

  // ============================================
  // MESSAGERIE
  // ============================================
  static const String messages = '$apiV1/messages';
  static const String conversations = '$messages/conversations';
  static String conversationById(String id) => '$conversations/$id';
  static String conversationMessages(String id) =>
      '$conversations/$id/messages';
  static String sendMessage(String conversationId) =>
      '$conversations/$conversationId/messages';
  static String markAsRead(String conversationId) =>
      '$conversations/$conversationId/read';

  // ============================================
  // ECOLES
  // ============================================
  static const String schools = '$apiV1/schools';
  static String schoolById(String id) => '$schools/$id';

  // ============================================
  // CHAT IA — AÏDA
  // ============================================
  static const String chat = '$apiV1/chat';
  static const String chatMessage = '$chat/message';
  static String chatSession(String sessionId) => '$chat/session/$sessionId';

  // ============================================
  // E-LEARNING
  // ============================================
  static const String elearning = '$apiV1/elearning';
  static const String elearningCourses = '$elearning/courses';
  static String elearningCourseById(String id) => '$elearningCourses/$id';
  static String elearningCourseEnroll(String id) => '$elearningCourses/$id/enroll';
  static const String elearningLessons = '$elearning/lessons';
  static String elearningLessonById(String id) => '$elearningLessons/$id';
  static String elearningLessonComplete(String id) => '$elearningLessons/$id/complete';
  static String elearningCourseExam(String id) => '$elearningCourses/$id/exam';
  static String elearningCourseExamSubmit(String id) => '$elearningCourses/$id/exam/submit';
  static const String elearningMyCourses = '$elearning/my-courses';

  // ============================================
  // GAMIFICATION
  // ============================================
  static const String gamification = '$apiV1/gamification';
  static const String gamificationProfile = '$gamification/profile';
  static const String achievements = '$gamification/achievements';
  static const String userAchievements = '$gamification/my-achievements';
  static const String challenges = '$gamification/challenges';
  static const String activeChallenges = '$gamification/challenges/active';
  static const String leaderboard = '$gamification/leaderboard';
  static const String weeklyLeaderboard = '$gamification/leaderboard/weekly';
  static const String dailyStreak = '$gamification/streak';

  // ============================================
  // OPPORTUNITIES - Stages, jobs, bourses
  // ============================================
  static const String opportunities = '$apiV1/opportunities';
  static String opportunityById(String id) => '$opportunities/$id';

  // ============================================
  // ANNOUNCEMENTS
  // ============================================
  static const String announcements = '$apiV1/announcements';

  // ============================================
  // SETTINGS
  // ============================================
  static const String publicSettings = '$apiV1/settings/public';

  // ============================================
  // RECHERCHE UNIFIEE
  // ============================================
  static const String search = '$apiV1/search';

  // ============================================
  // PARTNER (CDEJ, ONG) - Organizations & Beneficiaries
  // ============================================
  static const String partnerOrganizations = '$apiV1/partner/organizations';
  static String get partnerMyOrganization => '$partnerOrganizations/my-organization';
  static String partnerOrganizationById(String id) => '$partnerOrganizations/$id';
  static String partnerOrganizationStats(String id) => '$partnerOrganizations/$id/stats';
  static String partnerBeneficiaries(String orgId) => '$partnerOrganizations/$orgId/beneficiaries';
  static String partnerBeneficiaryById(String id) => '$apiV1/partner/beneficiaries/$id';
}
