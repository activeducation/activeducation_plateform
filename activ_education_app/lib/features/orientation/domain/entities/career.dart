import 'package:equatable/equatable.dart';

/// Represente un metier avec toutes les informations detaillees
/// pour guider les utilisateurs dans leur orientation professionnelle.
class Career extends Equatable {
  final String id;
  final String name;
  final String description;
  final String sector;
  final List<String> requiredSkills;
  final List<String> relatedTraits; // RIASEC, Intelligences, etc.
  final EducationPath educationPath;
  final SalaryInfo salaryInfo;
  final JobOutlook outlook;
  final String? imageUrl;
  // Champs de matching (remplis lors des recommandations)
  final double matchScore; // 0-100
  final List<String> matchingTraits;

  const Career({
    required this.id,
    required this.name,
    required this.description,
    required this.sector,
    required this.requiredSkills,
    required this.relatedTraits,
    required this.educationPath,
    required this.salaryInfo,
    required this.outlook,
    this.imageUrl,
    this.matchScore = 0,
    this.matchingTraits = const [],
  });

  @override
  List<Object?> get props => [id, name, sector];
}

/// Parcours d'etudes pour acceder au metier
class EducationPath extends Equatable {
  final String minimumLevel; // BAC, BAC+2, BAC+3, etc.
  final List<String> recommendedFormations;
  final List<String> schoolsInTogo; // Ecoles/universites au Togo
  final int durationYears;
  final String? certifications;

  const EducationPath({
    required this.minimumLevel,
    required this.recommendedFormations,
    required this.schoolsInTogo,
    required this.durationYears,
    this.certifications,
  });

  @override
  List<Object?> get props => [minimumLevel, recommendedFormations];
}

/// Informations sur les salaires au Togo
class SalaryInfo extends Equatable {
  final int minMonthlyFCFA; // Salaire minimum mensuel en FCFA
  final int maxMonthlyFCFA; // Salaire maximum mensuel en FCFA
  final int averageMonthlyFCFA; // Salaire moyen mensuel en FCFA
  final String experienceNote; // Note sur l'evolution avec l'experience

  const SalaryInfo({
    required this.minMonthlyFCFA,
    required this.maxMonthlyFCFA,
    required this.averageMonthlyFCFA,
    required this.experienceNote,
  });

  /// Formatage du salaire pour affichage
  String get formattedRange =>
      '${formatFCFA(minMonthlyFCFA)} - ${formatFCFA(maxMonthlyFCFA)} FCFA/mois';

  String get formattedAverage => '${formatFCFA(averageMonthlyFCFA)} FCFA/mois';

  /// Formate un montant en FCFA de maniere lisible
  static String formatFCFA(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }

  @override
  List<Object?> get props => [minMonthlyFCFA, maxMonthlyFCFA, averageMonthlyFCFA];
}

/// Perspectives d'emploi et tendances du marche
enum JobDemand { high, medium, low }
enum GrowthTrend { growing, stable, declining }

class JobOutlook extends Equatable {
  final JobDemand demand; // Demande actuelle
  final GrowthTrend trend; // Tendance de croissance
  final String description;
  final List<String> topEmployers; // Principaux employeurs au Togo
  final bool entrepreneurshipPotential; // Potentiel pour creer son entreprise

  const JobOutlook({
    required this.demand,
    required this.trend,
    required this.description,
    required this.topEmployers,
    required this.entrepreneurshipPotential,
  });

  String get demandLabel {
    switch (demand) {
      case JobDemand.high:
        return 'Forte demande';
      case JobDemand.medium:
        return 'Demande moderee';
      case JobDemand.low:
        return 'Faible demande';
    }
  }

  String get trendLabel {
    switch (trend) {
      case GrowthTrend.growing:
        return 'En croissance';
      case GrowthTrend.stable:
        return 'Stable';
      case GrowthTrend.declining:
        return 'En declin';
    }
  }

  @override
  List<Object?> get props => [demand, trend, entrepreneurshipPotential];
}
