import '../../domain/entities/test_result.dart';
import '../../domain/entities/career.dart';
import 'career_model.dart';

class TestResultModel extends TestResult {
  const TestResultModel({
    super.testId,
    required super.scores,
    required super.dominantTraits,
    required List<CareerModel> super.recommendations,
    super.interpretation,
    super.matchingPrograms,
  });

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    // Parse scores
    final rawScores = json['scores'] as Map<String, dynamic>? ?? {};
    final scores = rawScores.map((k, v) => MapEntry(k, (v as num).toDouble()));

    // Parse dominant traits
    final dominantTraits = (json['dominantTraits'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    // Parse recommendations
    final rawRecs = json['recommendations'] as List<dynamic>? ?? [];
    final recommendations = rawRecs
        .map((e) => _parseCareerSummary(e as Map<String, dynamic>))
        .toList();

    // Parse interpretation
    final rawInterp = json['interpretation'] as Map<String, dynamic>?;
    final interpretation = rawInterp != null
        ? _parseInterpretation(rawInterp)
        : null;

    // Parse matching programs
    final rawPrograms = json['matchingPrograms'] as List<dynamic>? ?? [];
    final matchingPrograms = rawPrograms
        .map((e) => _parseMatchingProgram(e as Map<String, dynamic>))
        .toList();

    return TestResultModel(
      testId: json['testId']?.toString(),
      scores: scores,
      dominantTraits: dominantTraits,
      recommendations: recommendations,
      interpretation: interpretation,
      matchingPrograms: matchingPrograms,
    );
  }
}

ProfileInterpretation _parseInterpretation(Map<String, dynamic> json) {
  // Parse trait details
  final rawDetails = json['trait_details'] as Map<String, dynamic>? ?? {};
  final traitDetails = rawDetails.map((k, v) {
    final detail = v as Map<String, dynamic>;
    return MapEntry(
      k,
      TraitDetail(
        score: (detail['score'] as num?)?.toDouble() ?? 0,
        description: detail['description'] as String? ?? '',
      ),
    );
  });

  return ProfileInterpretation(
    profileSummary: json['profile_summary'] as String? ?? '',
    profileCode: json['profile_code'] as String?,
    strengths: (json['strengths'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    workStyle: json['work_style'] as String? ?? '',
    advice: json['advice'] as String? ?? '',
    recommendedSectors: (json['recommended_sectors'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    traitDetails: traitDetails,
  );
}

MatchingProgram _parseMatchingProgram(Map<String, dynamic> json) {
  return MatchingProgram(
    programId: json['program_id'] as String? ?? '',
    programName: json['program_name'] as String? ?? '',
    programLevel: json['program_level'] as String?,
    programDuration: json['program_duration'] as int?,
    schoolId: json['school_id'] as String? ?? '',
    schoolName: json['school_name'] as String? ?? '',
    schoolCity: json['school_city'] as String?,
    schoolLogoUrl: json['school_logo_url'] as String?,
    schoolType: json['school_type'] as String?,
  );
}

/// Parse une carriere depuis le format enrichi du backend
CareerModel _parseCareerSummary(Map<String, dynamic> json) {
  // Si c'est un format complet CareerModel (camelCase avec educationPath)
  if (json.containsKey('educationPath')) {
    return CareerModel.fromJson(json);
  }

  // Format backend CareerSummary enrichi (snake_case)
  // Champs: id, name, description, sector_name, job_demand, salary_avg_fcfa,
  //         salary_min_fcfa, salary_max_fcfa, match_score, matching_traits,
  //         required_skills, related_traits, education_minimum_level, image_url
  return CareerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    sector: json['sector_name'] as String? ?? json['sector'] as String? ?? '',
    requiredSkills: (json['required_skills'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    relatedTraits: (json['related_traits'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    educationPath: EducationPathModel(
      minimumLevel: json['education_minimum_level'] as String? ?? 'BAC',
    ),
    salaryInfo: SalaryInfoModel(
      minMonthlyFCFA: json['salary_min_fcfa'] as int? ?? 0,
      maxMonthlyFCFA: json['salary_max_fcfa'] as int? ?? 0,
      averageMonthlyFCFA: json['salary_avg_fcfa'] as int? ?? 0,
    ),
    outlook: JobOutlookModel(
      demand: _parseJobDemand(json['job_demand'] as String?),
      trend: GrowthTrend.stable,
      description: '',
    ),
    imageUrl: json['image_url'] as String?,
    matchScore: (json['match_score'] as num?)?.toDouble() ?? 0,
    matchingTraits: (json['matching_traits'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );
}

JobDemand _parseJobDemand(String? value) {
  switch (value) {
    case 'high':
      return JobDemand.high;
    case 'low':
      return JobDemand.low;
    case 'medium':
    default:
      return JobDemand.medium;
  }
}
