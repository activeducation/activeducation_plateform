import '../../domain/entities/career.dart';

/// Model classes for Career that can be used for data layer operations.
class CareerModel extends Career {
  const CareerModel({
    required super.id,
    required super.name,
    required super.description,
    required super.sector,
    required super.requiredSkills,
    required super.relatedTraits,
    required EducationPathModel educationPath,
    required SalaryInfoModel salaryInfo,
    required JobOutlookModel outlook,
    super.imageUrl,
    super.matchScore = 0,
    super.matchingTraits = const [],
  }) : super(
          educationPath: educationPath,
          salaryInfo: salaryInfo,
          outlook: outlook,
        );

  factory CareerModel.fromJson(Map<String, dynamic> json) {
    return CareerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      relatedTraits: (json['relatedTraits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      educationPath: EducationPathModel.fromJson(
          json['educationPath'] as Map<String, dynamic>? ?? {}),
      salaryInfo: SalaryInfoModel.fromJson(
          json['salaryInfo'] as Map<String, dynamic>? ?? {}),
      outlook: JobOutlookModel.fromJson(
          json['outlook'] as Map<String, dynamic>? ?? {}),
      imageUrl: json['imageUrl'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0,
      matchingTraits: (json['matchingTraits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sector': sector,
      'requiredSkills': requiredSkills,
      'relatedTraits': relatedTraits,
      'educationPath': (educationPath as EducationPathModel).toJson(),
      'salaryInfo': (salaryInfo as SalaryInfoModel).toJson(),
      'outlook': (outlook as JobOutlookModel).toJson(),
      'imageUrl': imageUrl,
      'matchScore': matchScore,
      'matchingTraits': matchingTraits,
    };
  }
}

class EducationPathModel extends EducationPath {
  const EducationPathModel({
    super.minimumLevel = 'BAC',
    super.recommendedFormations = const [],
    super.schoolsInTogo = const [],
    super.durationYears = 3,
    super.certifications,
  });

  factory EducationPathModel.fromJson(Map<String, dynamic> json) {
    return EducationPathModel(
      minimumLevel: json['minimumLevel'] as String? ?? 'BAC',
      recommendedFormations: (json['recommendedFormations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      schoolsInTogo: (json['schoolsInTogo'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      durationYears: json['durationYears'] as int? ?? 3,
      certifications: json['certifications'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minimumLevel': minimumLevel,
      'recommendedFormations': recommendedFormations,
      'schoolsInTogo': schoolsInTogo,
      'durationYears': durationYears,
      'certifications': certifications,
    };
  }
}

class SalaryInfoModel extends SalaryInfo {
  const SalaryInfoModel({
    super.minMonthlyFCFA = 0,
    super.maxMonthlyFCFA = 0,
    super.averageMonthlyFCFA = 0,
    super.experienceNote = '',
  });

  factory SalaryInfoModel.fromJson(Map<String, dynamic> json) {
    return SalaryInfoModel(
      minMonthlyFCFA: json['minMonthlyFCFA'] as int? ?? 0,
      maxMonthlyFCFA: json['maxMonthlyFCFA'] as int? ?? 0,
      averageMonthlyFCFA: json['averageMonthlyFCFA'] as int? ?? 0,
      experienceNote: json['experienceNote'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minMonthlyFCFA': minMonthlyFCFA,
      'maxMonthlyFCFA': maxMonthlyFCFA,
      'averageMonthlyFCFA': averageMonthlyFCFA,
      'experienceNote': experienceNote,
    };
  }
}

class JobOutlookModel extends JobOutlook {
  const JobOutlookModel({
    super.demand = JobDemand.medium,
    super.trend = GrowthTrend.stable,
    super.description = '',
    super.topEmployers = const [],
    super.entrepreneurshipPotential = false,
  });

  factory JobOutlookModel.fromJson(Map<String, dynamic> json) {
    return JobOutlookModel(
      demand: _parseJobDemand(json['demand'] as String?),
      trend: _parseGrowthTrend(json['trend'] as String?),
      description: json['description'] as String? ?? '',
      topEmployers: (json['topEmployers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      entrepreneurshipPotential:
          json['entrepreneurshipPotential'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'demand': demand.toString().split('.').last,
      'trend': trend.toString().split('.').last,
      'description': description,
      'topEmployers': topEmployers,
      'entrepreneurshipPotential': entrepreneurshipPotential,
    };
  }

  static JobDemand _parseJobDemand(String? value) {
    switch (value) {
      case 'high':
        return JobDemand.high;
      case 'low':
        return JobDemand.low;
      default:
        return JobDemand.medium;
    }
  }

  static GrowthTrend _parseGrowthTrend(String? value) {
    switch (value) {
      case 'growing':
        return GrowthTrend.growing;
      case 'declining':
        return GrowthTrend.declining;
      default:
        return GrowthTrend.stable;
    }
  }
}
