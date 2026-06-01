import '../../domain/entities/organization.dart';

abstract class PartnerRepository {
  Future<Organization> createOrganization({
    required String name,
    required String type,
    String? description,
    String? contactEmail,
    String? contactPhone,
    String? contactPerson,
    String? address,
    String? city,
    String? country,
  });

  Future<Organization> getMyOrganization();
  Future<Organization> getOrganization(String orgId);
  Future<OrganizationWithStats> getOrganizationWithStats(String orgId);
  Future<List<Organization>> listOrganizations({
    int page = 1,
    int pageSize = 20,
    bool? isActive,
    bool? isApproved,
    String? orgType,
  });

  Future<Beneficiary> createBeneficiary({
    required String organizationId,
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? placeOfBirth,
    String? fatherName,
    String? motherName,
    String? guardianName,
    String? guardianPhone,
    String? guardianRelationship,
    String? address,
    String? city,
    String? country,
    String? photoUrl,
    String? notes,
  });

  Future<Beneficiary> getBeneficiary(String beneficiaryId);
  Future<Beneficiary> updateBeneficiary(
    String beneficiaryId,
    Map<String, dynamic> data,
  );
  Future<void> deleteBeneficiary(String beneficiaryId);
  Future<PaginatedBeneficiaries> listBeneficiaries({
    required String organizationId,
    int page = 1,
    int pageSize = 20,
    String? status,
  });
}