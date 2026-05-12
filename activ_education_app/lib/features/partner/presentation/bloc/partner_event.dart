part of 'partner_bloc.dart';

abstract class PartnerEvent extends Equatable {
  const PartnerEvent();

  @override
  List<Object?> get props => [];
}

class PartnerLoadOrganization extends PartnerEvent {
  final String organizationId;

  const PartnerLoadOrganization(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

class PartnerLoadOrganizationStats extends PartnerEvent {
  final String organizationId;

  const PartnerLoadOrganizationStats(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

class PartnerLoadBeneficiaries extends PartnerEvent {
  final String organizationId;
  final int page;
  final String? status;

  const PartnerLoadBeneficiaries({
    required this.organizationId,
    this.page = 1,
    this.status,
  });

  @override
  List<Object?> get props => [organizationId, page, status];
}

class PartnerLoadMoreBeneficiaries extends PartnerEvent {
  const PartnerLoadMoreBeneficiaries();
}

class PartnerCreateOrganization extends PartnerEvent {
  final String name;
  final String type;
  final String? description;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactPerson;
  final String? address;
  final String? city;
  final String? country;

  const PartnerCreateOrganization({
    required this.name,
    required this.type,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.contactPerson,
    this.address,
    this.city,
    this.country,
  });

  @override
  List<Object?> get props => [
        name,
        type,
        description,
        contactEmail,
        contactPhone,
        contactPerson,
        address,
        city,
        country,
      ];
}

class PartnerCreateBeneficiary extends PartnerEvent {
  final String organizationId;
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
  final String? country;
  final String? photoUrl;
  final String? notes;

  const PartnerCreateBeneficiary({
    required this.organizationId,
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
    this.country,
    this.photoUrl,
    this.notes,
  });

  @override
  List<Object?> get props => [
        organizationId,
        firstName,
        lastName,
        dateOfBirth,
        gender,
        placeOfBirth,
        fatherName,
        motherName,
        guardianName,
        guardianPhone,
        guardianRelationship,
        address,
        city,
        country,
        photoUrl,
        notes,
      ];
}

class PartnerUpdateBeneficiary extends PartnerEvent {
  final String beneficiaryId;
  final Map<String, dynamic> data;

  const PartnerUpdateBeneficiary({
    required this.beneficiaryId,
    required this.data,
  });

  @override
  List<Object?> get props => [beneficiaryId, data];
}

class PartnerDeleteBeneficiary extends PartnerEvent {
  final String beneficiaryId;

  const PartnerDeleteBeneficiary(this.beneficiaryId);

  @override
  List<Object?> get props => [beneficiaryId];
}