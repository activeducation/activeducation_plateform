import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/school_model.dart';

/// Repository pour les ecoles (appels API publics)
class SchoolRepository {
  final Dio _dio;

  SchoolRepository(this._dio);

  /// Liste paginee des ecoles avec filtres optionnels
  Future<SchoolListResponse> getSchools({
    String? search,
    String? city,
    String? type,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;

    final response = await _dio.get(
      ApiEndpoints.schools,
      queryParameters: queryParams,
    );

    return SchoolListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Detail complet d'une ecole
  Future<SchoolDetail> getSchoolDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.schoolById(id));
    return SchoolDetail.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Reponse paginee de la liste des ecoles
class SchoolListResponse {
  final List<SchoolSummary> items;
  final int total;
  final int page;
  final int perPage;

  const SchoolListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory SchoolListResponse.fromJson(Map<String, dynamic> json) {
    return SchoolListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SchoolSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
    );
  }
}
