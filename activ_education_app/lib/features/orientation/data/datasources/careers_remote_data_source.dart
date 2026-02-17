import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/career.dart';
import '../models/career_model.dart';

abstract class CareersRemoteDataSource {
  Future<List<Career>> getCareers({String? sector, int limit = 50});
  Future<Career> getCareerById(String id);
}

@LazySingleton(as: CareersRemoteDataSource)
class CareersRemoteDataSourceImpl implements CareersRemoteDataSource {
  final Dio _dio;

  CareersRemoteDataSourceImpl(@Named('apiClient') this._dio);

  @override
  Future<List<Career>> getCareers({String? sector, int limit = 50}) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (sector != null) queryParams['sector'] = sector;

      final response = await _dio.get(
        ApiEndpoints.careers,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => _parseCareer(json as Map<String, dynamic>)).toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Failed to load careers: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        'Erreur réseau lors du chargement des métiers: ${e.message}',
      );
    }
  }

  @override
  Future<Career> getCareerById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.careerById(id));

      if (response.statusCode == 200) {
        return _parseCareer(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Failed to load career: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        'Erreur réseau lors du chargement du métier: ${e.message}',
      );
    }
  }

  /// Parse la réponse API camelCase vers l'entité Career
  Career _parseCareer(Map<String, dynamic> json) {
    final educationJson = json['educationPath'] as Map<String, dynamic>? ?? {};
    final salaryJson = json['salaryInfo'] as Map<String, dynamic>? ?? {};
    final outlookJson = json['outlook'] as Map<String, dynamic>? ?? {};

    return CareerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      relatedTraits: List<String>.from(json['relatedTraits'] ?? []),
      educationPath: EducationPathModel(
        minimumLevel: educationJson['minimumLevel'] as String? ?? 'BAC',
        recommendedFormations: List<String>.from(educationJson['recommendedFormations'] ?? []),
        schoolsInTogo: List<String>.from(educationJson['schoolsInTogo'] ?? []),
        durationYears: educationJson['durationYears'] as int? ?? 3,
        certifications: educationJson['certifications'] as String?,
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: salaryJson['minMonthlyFCFA'] as int? ?? 0,
        maxMonthlyFCFA: salaryJson['maxMonthlyFCFA'] as int? ?? 0,
        averageMonthlyFCFA: salaryJson['averageMonthlyFCFA'] as int? ?? 0,
        experienceNote: salaryJson['experienceNote'] as String? ?? '',
      ),
      outlook: JobOutlookModel(
        demand: _parseJobDemand(outlookJson['demand'] as String?),
        trend: _parseGrowthTrend(outlookJson['trend'] as String?),
        description: outlookJson['description'] as String? ?? '',
        topEmployers: List<String>.from(outlookJson['topEmployers'] ?? []),
        entrepreneurshipPotential: outlookJson['entrepreneurshipPotential'] as bool? ?? false,
      ),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  JobDemand _parseJobDemand(String? value) {
    switch (value) {
      case 'high':
        return JobDemand.high;
      case 'low':
        return JobDemand.low;
      default:
        return JobDemand.medium;
    }
  }

  GrowthTrend _parseGrowthTrend(String? value) {
    switch (value) {
      case 'growing':
        return GrowthTrend.growing;
      case 'declining':
        return GrowthTrend.declining;
      default:
        return GrowthTrend.stable;
    }
  }
}
