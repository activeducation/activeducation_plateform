/// Entity for organization partner (CDEJ, ONG, etc.)
class Organization {
  final String id;
  final String name;
  final String type;
  final String? partnerCode;
  final String? description;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactPerson;
  final String? address;
  final String? city;
  final String country;
  final bool isActive;
  final bool isApproved;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Organization({
    required this.id,
    required this.name,
    required this.type,
    this.partnerCode,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.contactPerson,
    this.address,
    this.city,
    this.country = 'TOGO',
    this.isActive = true,
    this.isApproved = false,
    this.approvedAt,
    required this.createdAt,
    this.updatedAt,
  });

  String get typeLabel {
    switch (type) {
      case 'cdej':
        return 'CDEJ';
      case 'ong':
        return 'ONG';
      case 'school':
        return 'École';
      default:
        return 'Autre';
    }
  }
}

/// Entity for organization with statistics
class OrganizationWithStats {
  final Organization organization;
  final int totalBeneficiaries;
  final int activeBeneficiaries;
  final int completedBeneficiaries;

  const OrganizationWithStats({
    required this.organization,
    required this.totalBeneficiaries,
    required this.activeBeneficiaries,
    required this.completedBeneficiaries,
  });
}

/// Entity for beneficiary dossier
class Beneficiary {
  final String id;
  final String organizationId;
  final String? dossierNumber;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? placeOfBirth;
  final String? fatherName;
  final String? motherName;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelationship;
  final String? address;
  final String? city;
  final String country;
  final String? photoUrl;
  final String? notes;
  final String status;
  final DateTime referredAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Beneficiary({
    required this.id,
    required this.organizationId,
    this.dossierNumber,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.placeOfBirth,
    this.fatherName,
    this.motherName,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelationship,
    this.address,
    this.city,
    this.country = 'TOGO',
    this.photoUrl,
    this.notes,
    this.status = 'active',
    required this.referredAt,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'transferred':
        return 'Transféré';
      case 'completed':
        return 'Complété';
      default:
        return status;
    }
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}