// Modeles de l'ecran "Donnees d'orientation" (moteur multi-criteres).

class CareerSubjects {
  final String id;
  final String name;
  final List<String> keySubjects;
  final bool isActive;

  const CareerSubjects({
    required this.id,
    required this.name,
    this.keySubjects = const [],
    this.isActive = true,
  });

  factory CareerSubjects.fromJson(Map<String, dynamic> json) {
    return CareerSubjects(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Metier',
      keySubjects:
          (json['key_subjects'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// True quand le critere "notes" est inactif pour ce metier.
  bool get isMissing => keySubjects.isEmpty;

  CareerSubjects copyWith({List<String>? keySubjects}) => CareerSubjects(
        id: id,
        name: name,
        keySubjects: keySubjects ?? this.keySubjects,
        isActive: isActive,
      );
}

class ProgramCost {
  final String id;
  final String name;
  final String? degreeLevel;
  final int? tuitionAnnualFcfa;
  final bool? isPublic;

  const ProgramCost({
    required this.id,
    required this.name,
    this.degreeLevel,
    this.tuitionAnnualFcfa,
    this.isPublic,
  });

  factory ProgramCost.fromJson(Map<String, dynamic> json) {
    return ProgramCost(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Formation',
      degreeLevel: json['degree_level'] as String?,
      tuitionAnnualFcfa: (json['tuition_annual_fcfa'] as num?)?.toInt(),
      isPublic: json['is_public'] as bool?,
    );
  }

  /// True quand le critere "budget" est inactif pour cette formation.
  bool get isMissing => tuitionAnnualFcfa == null;

  ProgramCost copyWith({int? tuitionAnnualFcfa, bool? isPublic}) => ProgramCost(
        id: id,
        name: name,
        degreeLevel: degreeLevel,
        tuitionAnnualFcfa: tuitionAnnualFcfa ?? this.tuitionAnnualFcfa,
        isPublic: isPublic ?? this.isPublic,
      );
}
