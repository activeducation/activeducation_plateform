/// Modele de programme/filiere d'une ecole
class SchoolProgram {
  final String id;
  final String name;
  final String? description;
  final String? level;
  final int? durationYears;

  const SchoolProgram({
    required this.id,
    required this.name,
    this.description,
    this.level,
    this.durationYears,
  });

  factory SchoolProgram.fromJson(Map<String, dynamic> json) {
    return SchoolProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      level: json['level'] as String?,
      durationYears: json['duration_years'] as int?,
    );
  }

  /// Label lisible pour le niveau
  String get levelLabel {
    switch (level) {
      case 'bts':
        return 'BTS';
      case 'licence':
        return 'Licence';
      case 'master':
        return 'Master';
      case 'doctorat':
        return 'Doctorat';
      default:
        return level ?? '';
    }
  }

  /// Duree formatee
  String get durationLabel {
    if (durationYears == null) return '';
    return '$durationYears an${durationYears! > 1 ? 's' : ''}';
  }
}

/// Modele d'image d'ecole
class SchoolImage {
  final String id;
  final String imageUrl;
  final String? caption;

  const SchoolImage({
    required this.id,
    required this.imageUrl,
    this.caption,
  });

  factory SchoolImage.fromJson(Map<String, dynamic> json) {
    return SchoolImage(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
    );
  }
}

/// Modele resume d'une ecole (pour la liste)
class SchoolSummary {
  final String id;
  final String name;
  final String type;
  final String city;
  final bool isPublic;
  final String? logoUrl;
  final String? description;
  final List<String> programsOffered;
  final List<String> accreditations;
  final String? tuitionRange;
  final int? studentCount;
  final int? foundingYear;
  final int programsCount;

  const SchoolSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    this.isPublic = true,
    this.logoUrl,
    this.description,
    this.programsOffered = const [],
    this.accreditations = const [],
    this.tuitionRange,
    this.studentCount,
    this.foundingYear,
    this.programsCount = 0,
  });

  factory SchoolSummary.fromJson(Map<String, dynamic> json) {
    return SchoolSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      city: json['city'] as String,
      isPublic: json['is_public'] as bool? ?? true,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      programsOffered: (json['programs_offered'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      accreditations: (json['accreditations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tuitionRange: json['tuition_range'] as String?,
      studentCount: json['student_count'] as int?,
      foundingYear: json['founding_year'] as int?,
      programsCount: json['programs_count'] as int? ?? 0,
    );
  }

  /// Label du type d'etablissement
  String get typeLabel {
    switch (type) {
      case 'university':
        return 'Universite';
      case 'grande_ecole':
        return 'Grande Ecole';
      case 'institut':
        return 'Institut';
      case 'centre_formation':
        return 'Centre de Formation';
      default:
        return type;
    }
  }

  /// Badge Publique / Privee
  String get statusLabel => isPublic ? 'Publique' : 'Privee';
}

/// Modele detail complet d'une ecole
class SchoolDetail {
  final String id;
  final String name;
  final String type;
  final String city;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final List<String> programsOffered;
  final bool isPublic;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? tuitionRange;
  final String? admissionRequirements;
  final List<String> accreditations;
  final int? foundingYear;
  final int? studentCount;
  final List<SchoolProgram> programs;
  final List<SchoolImage> images;

  const SchoolDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.programsOffered = const [],
    this.isPublic = true,
    this.logoUrl,
    this.coverImageUrl,
    this.tuitionRange,
    this.admissionRequirements,
    this.accreditations = const [],
    this.foundingYear,
    this.studentCount,
    this.programs = const [],
    this.images = const [],
  });

  factory SchoolDetail.fromJson(Map<String, dynamic> json) {
    return SchoolDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      city: json['city'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      programsOffered: (json['programs_offered'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isPublic: json['is_public'] as bool? ?? true,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      tuitionRange: json['tuition_range'] as String?,
      admissionRequirements: json['admission_requirements'] as String?,
      accreditations: (json['accreditations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      foundingYear: json['founding_year'] as int?,
      studentCount: json['student_count'] as int?,
      programs: (json['programs'] as List<dynamic>?)
              ?.map((e) => SchoolProgram.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => SchoolImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Label du type
  String get typeLabel {
    switch (type) {
      case 'university':
        return 'Universite';
      case 'grande_ecole':
        return 'Grande Ecole';
      case 'institut':
        return 'Institut';
      case 'centre_formation':
        return 'Centre de Formation';
      default:
        return type;
    }
  }

  String get statusLabel => isPublic ? 'Publique' : 'Privee';
}
