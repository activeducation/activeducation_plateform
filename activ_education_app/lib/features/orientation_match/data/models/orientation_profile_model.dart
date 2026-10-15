// Profil d'orientation multi-critères (miroir de /orientation/profile).

class OrientationProfileModel {
  final Map<String, double> grades; // matière -> note /20
  final List<String> favoriteSubjects;
  final List<String> interests;
  final int? budgetAnnualFcfa;
  final String? careerProject;

  const OrientationProfileModel({
    this.grades = const {},
    this.favoriteSubjects = const [],
    this.interests = const [],
    this.budgetAnnualFcfa,
    this.careerProject,
  });

  factory OrientationProfileModel.empty() => const OrientationProfileModel();

  factory OrientationProfileModel.fromJson(Map<String, dynamic> json) {
    final rawGrades = (json['grades'] as Map?) ?? const {};
    return OrientationProfileModel(
      grades: rawGrades.map(
        (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0),
      ),
      favoriteSubjects: (json['favorite_subjects'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      interests:
          (json['interests'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      budgetAnnualFcfa: (json['budget_annual_fcfa'] as num?)?.toInt(),
      careerProject: json['career_project'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'grades': grades,
        'favorite_subjects': favoriteSubjects,
        'interests': interests,
        'budget_annual_fcfa': budgetAnnualFcfa,
        'career_project': careerProject,
      };

  OrientationProfileModel copyWith({
    Map<String, double>? grades,
    List<String>? favoriteSubjects,
    List<String>? interests,
    int? budgetAnnualFcfa,
    bool clearBudget = false,
    String? careerProject,
  }) {
    return OrientationProfileModel(
      grades: grades ?? this.grades,
      favoriteSubjects: favoriteSubjects ?? this.favoriteSubjects,
      interests: interests ?? this.interests,
      budgetAnnualFcfa:
          clearBudget ? null : (budgetAnnualFcfa ?? this.budgetAnnualFcfa),
      careerProject: careerProject ?? this.careerProject,
    );
  }
}
