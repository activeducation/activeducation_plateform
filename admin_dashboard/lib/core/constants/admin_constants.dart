class AdminConstants {
  AdminConstants._();

  static const String appName = 'ActivEducation Admin';
  static const String appVersion = '1.0.0';

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  static const List<String> userRoles = ['student', 'admin', 'super_admin'];
  static const List<String> schoolTypes = ['university', 'grande_ecole', 'institut', 'centre_formation'];
  static const List<String> testTypes = ['riasec', 'personality', 'skills', 'interests', 'aptitude'];
  static const List<String> questionTypes = ['likert', 'multiple_choice', 'boolean'];
  static const List<String> jobDemands = ['high', 'medium', 'low'];
  static const List<String> growthTrends = ['growing', 'stable', 'declining'];
  static const List<String> announcementTypes = ['info', 'warning', 'promotion', 'update'];
  static const List<String> targetAudiences = ['all', 'students', 'mentors', 'admins'];

  static const List<String> riasecCategories = [
    'Realistic', 'Investigative', 'Artistic', 'Social', 'Enterprising', 'Conventional'
  ];

  static const Map<String, String> roleLabels = {
    'student': 'Etudiant',
    'admin': 'Administrateur',
    'super_admin': 'Super Admin',
  };

  static const Map<String, String> schoolTypeLabels = {
    'university': 'Universite',
    'grande_ecole': 'Grande Ecole',
    'institut': 'Institut',
    'centre_formation': 'Centre de Formation',
  };

  static const List<String> programLevels = ['bts', 'licence', 'master', 'doctorat'];

  static const Map<String, String> programLevelLabels = {
    'bts': 'BTS',
    'licence': 'Licence',
    'master': 'Master',
    'doctorat': 'Doctorat',
  };
}
