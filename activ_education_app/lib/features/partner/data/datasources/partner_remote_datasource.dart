import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/partner_models.dart';

/// Data source for partner API operations
abstract class PartnerRemoteDataSource {
  Future<OrganizationModel> createOrganization({
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

  Future<OrganizationModel> getOrganization(String orgId);
  Future<OrganizationWithStatsModel> getOrganizationWithStats(String orgId);
  Future<List<OrganizationModel>> listOrganizations({
    int page = 1,
    int pageSize = 20,
    bool? isActive,
    bool? isApproved,
    String? orgType,
  });

  Future<BeneficiaryModel> createBeneficiary({
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

  Future<BeneficiaryModel> getBeneficiary(String beneficiaryId);
  Future<BeneficiaryModel> updateBeneficiary(
    String beneficiaryId,
    Map<String, dynamic> data,
  );
  Future<void> deleteBeneficiary(String beneficiaryId);
  Future<PaginatedBeneficiariesModel> listBeneficiaries({
    required String organizationId,
    int page = 1,
    int pageSize = 20,
    String? status,
  });
}

@LazySingleton(as: PartnerRemoteDataSource)
class PartnerRemoteDataSourceImpl implements PartnerRemoteDataSource {
  final Dio _dio;

  PartnerRemoteDataSourceImpl(@Named('apiClient') this._dio);

  @override
  Future<OrganizationModel> createOrganization({
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
    try {
      final response = await _dio.post(
        ApiEndpoints.partnerOrganizations,
        data: {
          'name': name,
          'type': type,
          'description': ?description,
          'contact_email': ?contactEmail,
          'contact_phone': ?contactPhone,
          'contact_person': ?contactPerson,
          'address': ?address,
          'city': ?city,
          'country': ?country,
        },
      );
      return OrganizationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    try {
      final response = await _dio.get(ApiEndpoints.partnerOrganizationById(orgId));
      return OrganizationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OrganizationWithStatsModel> getOrganizationWithStats(String orgId) async {
    try {
      final response = await _dio.get(ApiEndpoints.partnerOrganizationStats(orgId));
      return OrganizationWithStatsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<OrganizationModel>> listOrganizations({
    int page = 1,
    int pageSize = 20,
    bool? isActive,
    bool? isApproved,
    String? orgType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'is_active': ?isActive,
        'is_approved': ?isApproved,
        'org_type': ?orgType,
      };

      final response = await _dio.get(
        ApiEndpoints.partnerOrganizations,
        queryParameters: queryParams,
      );

      final organizations = response.data['organizations'] as List<dynamic>;
      return organizations
          .map((e) => OrganizationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BeneficiaryModel> createBeneficiary({
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
    try {
      final response = await _dio.post(
        ApiEndpoints.partnerBeneficiaries(organizationId),
        data: {
          'first_name': firstName,
          'last_name': lastName,
          if (dateOfBirth != null)
            'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
          'gender': ?gender,
          'place_of_birth': ?placeOfBirth,
          'father_name': ?fatherName,
          'mother_name': ?motherName,
          'guardian_name': ?guardianName,
          'guardian_phone': ?guardianPhone,
          'guardian_relationship': ?guardianRelationship,
          'address': ?address,
          'city': ?city,
          'country': ?country,
          'photo_url': ?photoUrl,
          'notes': ?notes,
        },
      );
      return BeneficiaryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BeneficiaryModel> getBeneficiary(String beneficiaryId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.partnerBeneficiaryById(beneficiaryId),
      );
      return BeneficiaryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BeneficiaryModel> updateBeneficiary(
    String beneficiaryId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.partnerBeneficiaryById(beneficiaryId),
        data: data,
      );
      return BeneficiaryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteBeneficiary(String beneficiaryId) async {
    try {
      await _dio.delete(ApiEndpoints.partnerBeneficiaryById(beneficiaryId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PaginatedBeneficiariesModel> listBeneficiaries({
    required String organizationId,
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'status': ?status,
      };

      final response = await _dio.get(
        ApiEndpoints.partnerBeneficiaries(organizationId),
        queryParameters: queryParams,
      );

      return PaginatedBeneficiariesModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map && data['message'] != null) {
        message = data['message'];
      } else if (data is Map && data['detail'] != null) {
        message = data['detail'].toString();
      }

      switch (statusCode) {
        case 400:
          return PartnerException(PartnerExceptionType.validation, message);
        case 401:
          return PartnerException(PartnerExceptionType.unauthorized, message);
        case 403:
          return PartnerException(PartnerExceptionType.forbidden, message);
        case 404:
          return PartnerException(PartnerExceptionType.notFound, message);
        default:
          return PartnerException(PartnerExceptionType.server, message);
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return PartnerException(PartnerExceptionType.timeout, 'Connexion timeout');
    }

    if (e.type == DioExceptionType.connectionError) {
      return PartnerException(PartnerExceptionType.network, 'Erreur de connexion');
    }

    return PartnerException(
      PartnerExceptionType.unknown,
      e.message ?? 'Erreur inconnue',
    );
  }
}

enum PartnerExceptionType {
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  network,
  timeout,
  unknown,
}

class PartnerException implements Exception {
  final PartnerExceptionType type;
  final String message;

  PartnerException(this.type, this.message);

  @override
  String toString() => 'PartnerException($type): $message';
}