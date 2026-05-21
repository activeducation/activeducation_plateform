import '../../domain/entities/organization.dart';

/// Model for Organization with JSON serialization
class OrganizationModel extends Organization {
  const OrganizationModel({
    required super.id,
    required super.name,
    required super.type,
    super.partnerCode,
    super.description,
    super.contactEmail,
    super.contactPhone,
    super.contactPerson,
    super.address,
    super.city,
    super.country,
    super.isActive,
    super.isApproved,
    super.approvedAt,
    required super.createdAt,
    super.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'cdej',
      partnerCode: json['partner_code'] as String?,
      description: json['description'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactPerson: json['contact_person'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String? ?? 'TOGO',
      isActive: json['is_active'] as bool? ?? true,
      isApproved: json['is_approved'] as bool? ?? false,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'contact_person': contactPerson,
      'address': address,
      'city': city,
      'country': country,
    };
  }

  Organization toEntity() => this;
}

/// Model for Organization with statistics
class OrganizationWithStatsModel extends OrganizationWithStats {
  const OrganizationWithStatsModel({
    required super.organization,
    required super.totalBeneficiaries,
    required super.activeBeneficiaries,
    required super.completedBeneficiaries,
  });

  factory OrganizationWithStatsModel.fromJson(Map<String, dynamic> json) {
    return OrganizationWithStatsModel(
      organization: OrganizationModel.fromJson(
        json['organization'] as Map<String, dynamic>,
      ),
      totalBeneficiaries: json['total_beneficiaries'] as int? ?? 0,
      activeBeneficiaries: json['active_beneficiaries'] as int? ?? 0,
      completedBeneficiaries: json['completed_beneficiaries'] as int? ?? 0,
    );
  }
}

/// Model for Beneficiary with JSON serialization
class BeneficiaryModel extends Beneficiary {
  const BeneficiaryModel({
    required super.id,
    required super.organizationId,
    super.dossierNumber,
    required super.firstName,
    required super.lastName,
    super.dateOfBirth,
    super.gender,
    super.placeOfBirth,
    super.fatherName,
    super.motherName,
    super.guardianName,
    super.guardianPhone,
    super.guardianRelationship,
    super.address,
    super.city,
    super.country,
    super.photoUrl,
    super.notes,
    super.status,
    required super.referredAt,
    required super.createdAt,
    super.updatedAt,
  });

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      dossierNumber: json['dossier_number'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      guardianRelationship: json['guardian_relationship'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String? ?? 'TOGO',
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
      referredAt: DateTime.parse(json['referred_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'gender': gender,
      'place_of_birth': placeOfBirth,
      'father_name': fatherName,
      'mother_name': motherName,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'guardian_relationship': guardianRelationship,
      'address': address,
      'city': city,
      'country': country,
      'photo_url': photoUrl,
      'notes': notes,
    };
  }

  Beneficiary toEntity() => this;
}

/// Model for paginated list response
class PaginatedBeneficiariesModel {
  final List<BeneficiaryModel> beneficiaries;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedBeneficiariesModel({
    required this.beneficiaries,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedBeneficiariesModel.fromJson(Map<String, dynamic> json) {
    return PaginatedBeneficiariesModel(
      beneficiaries: (json['beneficiaries'] as List<dynamic>)
          .map((e) => BeneficiaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
    );
  }

  PaginatedBeneficiaries toEntity() {
    return PaginatedBeneficiaries(
      beneficiaries: beneficiaries.cast<Beneficiary>(),
      total: total,
      page: page,
      pageSize: pageSize,
    );
  }
}