class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // Admin Auth
  static const String adminLogin = '/admin/auth/login';

  // Dashboard
  static const String dashboardStats = '/admin/dashboard/stats';

  // Users
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static String adminUserDeactivate(String id) => '/admin/users/$id/deactivate';
  static String adminUserActivate(String id) => '/admin/users/$id/activate';

  // Schools
  static const String adminSchools = '/admin/schools';
  static String adminSchoolById(String id) => '/admin/schools/$id';
  static String adminSchoolVerify(String id) => '/admin/schools/$id/verify';
  static String adminSchoolToggleActive(String id) => '/admin/schools/$id/toggle-active';
  static String adminSchoolPrograms(String id) => '/admin/schools/$id/programs';
  static String adminSchoolProgramById(String schoolId, String programId) =>
      '/admin/schools/$schoolId/programs/$programId';
  static String adminSchoolImages(String id) => '/admin/schools/$id/images';
  static String adminSchoolImageById(String schoolId, String imageId) =>
      '/admin/schools/$schoolId/images/$imageId';

  // Careers
  static const String adminCareers = '/admin/careers';
  static String adminCareerById(String id) => '/admin/careers/$id';
  static const String adminSectors = '/admin/careers/sectors';
  static String adminSectorById(String id) => '/admin/careers/sectors/$id';

  // Tests
  static const String adminTests = '/admin/tests';
  static String adminTestById(String id) => '/admin/tests/$id';
  static String adminTestDuplicate(String id) => '/admin/tests/$id/duplicate';
  static String adminTestQuestions(String id) => '/admin/tests/$id/questions';
  static String adminTestQuestionById(String testId, String qId) =>
      '/admin/tests/$testId/questions/$qId';
  static String adminTestQuestionReorder(String testId) =>
      '/admin/tests/$testId/questions/reorder';

  // Gamification
  static const String adminAchievements = '/admin/gamification/achievements';
  static String adminAchievementById(String id) => '/admin/gamification/achievements/$id';
  static const String adminChallenges = '/admin/gamification/challenges';
  static String adminChallengeById(String id) => '/admin/gamification/challenges/$id';

  // Mentors
  static const String adminMentors = '/admin/mentors';
  static String adminMentorById(String id) => '/admin/mentors/$id';
  static String adminMentorVerify(String id) => '/admin/mentors/$id/verify';
  static String adminMentorToggleActive(String id) => '/admin/mentors/$id/toggle-active';

  // Settings
  static const String adminSettings = '/admin/settings';
  static String adminSettingByKey(String key) => '/admin/settings/$key';
  static const String adminAnnouncements = '/admin/announcements';
  static String adminAnnouncementById(String id) => '/admin/announcements/$id';
  static const String adminAuditLog = '/admin/audit-log';

  // Upload
  static String adminUpload(String bucket) => '/admin/upload/$bucket';
}
