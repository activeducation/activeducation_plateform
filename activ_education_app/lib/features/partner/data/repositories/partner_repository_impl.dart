import 'package:injectable/injectable.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/partner_repository.dart';
import '../datasources/partner_remote_datasource.dart';
import '../models/partner_models.dart';

@LazySingleton(as: PartnerRepository)
class PartnerRepositoryImpl implements PartnerRepository {
  final PartnerRemoteDataSource _remoteDataSource;

  PartnerRepositoryImpl(this._remoteDataSource);

  @override
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
  }) async {
    final model = await _remoteDataSource.createOrganization(
      name: name,
      type: type,
      description: description,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactPerson: contactPerson,
      address: address,
      city: city,
      country: country,
    );
    return model.toEntity();
  }

  @override
  Future<Organization> getOrganization(String orgId) async {
    final model = await _remoteDataSource.getOrganization(orgId);
    return model.toEntity();
  }

  @override
  Future<OrganizationWithStats> getOrganizationWithStats(String orgId) async {
    final model = await _remoteDataSource.getOrganizationWithStats(orgId);
    return OrganizationWithStats(
      organization: model.organization,
      totalBeneficiaries: model.totalBeneficiaries,
      activeBeneficiaries: model.activeBeneficiaries,
      completedBeneficiaries: model.completedBeneficiaries,
    );
  }

  @override
  Future<List<Organization>> listOrganizations({
    int page = 1,
    int pageSize = 20,
    bool? isActive,
    bool? isApproved,
    String? orgType,
  }) async {
    final models = await _remoteDataSource.listOrganizations(
      page: page,
      pageSize: pageSize,
      isActive: isActive,
      isApproved: isApproved,
      orgType: orgType,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
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
  }) async {
    final model = await _remoteDataSource.createBeneficiary(
      organizationId: organizationId,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      placeOfBirth: placeOfBirth,
      fatherName: fatherName,
      motherName: motherName,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      guardianRelationship: guardianRelationship,
      address: address,
      city: city,
      country: country,
      photoUrl: photoUrl,
      notes: notes,
    );
    return model.toEntity();
  }

  @override
  Future<Beneficiary> getBeneficiary(String beneficiaryId) async {
    final model = await _remoteDataSource.getBeneficiary(beneficiaryId);
    return model.toEntity();
  }

  @override
  Future<Beneficiary> updateBeneficiary(
    String beneficiaryId,
    Map<String, dynamic> data,
  ) async {
    final model = await _remoteDataSource.updateBeneficiary(
      beneficiaryId,
      data,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteBeneficiary(String beneficiaryId) async {
    await _remoteDataSource.deleteBeneficiary(beneficiaryId);
  }

  @override
  Future<PaginatedBeneficiaries> listBeneficiaries({
    required String organizationId,
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final model = await _remoteDataSource.listBeneficiaries(
      organizationId: organizationId,
      page: page,
      pageSize: pageSize,
      status: status,
    );
    return model.toEntity();
  }
}