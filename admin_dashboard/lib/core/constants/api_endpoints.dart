class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://localhost:8000/api/v1',
  );

  // Admin Auth
  static const String adminLogin = '/admin/auth/login';

  // School Admin Auth
  static const String schoolAdminLogin = '/school/auth/login';

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
  static String adminSchoolToggleActive(String id) =>
      '/admin/schools/$id/toggle-active';
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
  static String adminAchievementById(String id) =>
      '/admin/gamification/achievements/$id';
  static const String adminChallenges = '/admin/gamification/challenges';
  static String adminChallengeById(String id) =>
      '/admin/gamification/challenges/$id';

  // Mentors
  static const String adminMentors = '/admin/mentors';
  static String adminMentorById(String id) => '/admin/mentors/$id';
  static String adminMentorVerify(String id) => '/admin/mentors/$id/verify';
  static String adminMentorToggleActive(String id) =>
      '/admin/mentors/$id/toggle-active';
  static String adminMentorTasks(String id) => '/admin/mentors/$id/tasks';
  static String adminMentorTaskById(String id) => '/admin/mentors/tasks/$id';

  // Candidatures mentor
  static const String adminMentorApplications = '/admin/mentor-applications';
  static String adminMentorAppApprove(String id) =>
      '/admin/mentor-applications/$id/approve';
  static String adminMentorAppReject(String id) =>
      '/admin/mentor-applications/$id/reject';

  // Settings
  static const String adminSettings = '/admin/settings';
  static String adminSettingByKey(String key) => '/admin/settings/$key';
  static const String adminAnnouncements = '/admin/announcements';
  static String adminAnnouncementById(String id) => '/admin/announcements/$id';
  static const String adminAuditLog = '/admin/audit-log';

  // E-Learning
  static const String adminElearningCourses = '/admin/elearning/courses';
  static String adminElearningCourseById(String id) => '/admin/elearning/courses/$id';
  static String adminElearningCoursePublish(String id) => '/admin/elearning/courses/$id/publish';
  static String adminElearningCourseModules(String id) => '/admin/elearning/courses/$id/modules';
  static const String adminElearningSchools = '/admin/elearning/schools';

  // E-Learning Modules
  static String adminElearningModule(String id) => '/admin/elearning/modules/$id';
  static String adminElearningModuleLessons(String id) => '/admin/elearning/modules/$id/lessons';

  // E-Learning Lessons
  static String adminElearningLesson(String id) => '/admin/elearning/lessons/$id';
  static String adminElearningCourseExam(String id) => '/admin/elearning/courses/$id/exam';

  // Opportunities
  static const String adminOpportunities = '/admin/opportunities';
  static String adminOpportunityById(String id) => '/admin/opportunities/$id';
  static String adminOpportunityPublish(String id) => '/admin/opportunities/$id/publish';
  static String adminOpportunityFeatured(String id) => '/admin/opportunities/$id/featured';

  // Upload
  static String adminUpload(String bucket) => '/admin/upload/$bucket';

  // School Admin (E-Learning)
  static const String schoolCourses = '/school/courses';
  static String schoolCourseById(String id) => '/school/courses/$id';
  static String schoolCoursePublish(String id) => '/school/courses/$id/publish';
  static String schoolCourseModules(String id) => '/school/courses/$id/modules';
  static const String schoolProfile = '/school/profile';
  static const String schoolDashboard = '/school/dashboard';

  // School Admin Modules
  static String schoolModule(String id) => '/school/modules/$id';
  static String schoolModuleLessons(String id) => '/school/modules/$id/lessons';

  // School Admin Lessons
  static String schoolLesson(String id) => '/school/lessons/$id';
  static String schoolLessonUploadVideo(String id) => '/school/lessons/$id/upload-video';

  // Partner
  static String adminApproveOrg(String id) => '/admin/partner/organizations/$id/approve';

  // Donnees d'orientation (moteur multi-criteres)
  static const String adminOrientationCareers = '/admin/orientation-data/careers';
  static const String adminOrientationPrograms = '/admin/orientation-data/programs';
  static String adminOrientationCareer(String id) =>
      '/admin/orientation-data/careers/$id';
  static String adminOrientationProgram(String id) =>
      '/admin/orientation-data/programs/$id';
}
