import 'package:equatable/equatable.dart';
import 'career.dart';

/// Interpretation structuree du profil
class ProfileInterpretation extends Equatable {
  final String profileSummary;
  final String? profileCode;
  final List<String> strengths;
  final String workStyle;
  final String advice;
  final List<String> recommendedSectors;
  final Map<String, TraitDetail> traitDetails;

  const ProfileInterpretation({
    required this.profileSummary,
    this.profileCode,
    this.strengths = const [],
    this.workStyle = '',
    this.advice = '',
    this.recommendedSectors = const [],
    this.traitDetails = const {},
  });

  @override
  List<Object?> get props => [profileSummary, profileCode, strengths];
}

/// Detail d'un trait RIASEC
class TraitDetail extends Equatable {
  final double score;
  final String description;

  const TraitDetail({required this.score, this.description = ''});

  @override
  List<Object?> get props => [score, description];
}

/// Programme scolaire recommande
class MatchingProgram extends Equatable {
  final String programId;
  final String programName;
  final String? programLevel;
  final int? programDuration;
  final String schoolId;
  final String schoolName;
  final String? schoolCity;
  final String? schoolLogoUrl;
  final String? schoolType;

  const MatchingProgram({
    required this.programId,
    required this.programName,
    this.programLevel,
    this.programDuration,
    required this.schoolId,
    required this.schoolName,
    this.schoolCity,
    this.schoolLogoUrl,
    this.schoolType,
  });

  @override
  List<Object?> get props => [programId, schoolId];
}

class TestResult extends Equatable {
  final String? testId;
  final Map<String, double> scores;
  final List<String> dominantTraits;
  final List<Career> recommendations;
  final ProfileInterpretation? interpretation;
  final List<MatchingProgram> matchingPrograms;

  const TestResult({
    this.testId,
    required this.scores,
    required this.dominantTraits,
    required this.recommendations,
    this.interpretation,
    this.matchingPrograms = const [],
  });

  @override
  List<Object?> get props => [testId, scores, dominantTraits, recommendations];
}
