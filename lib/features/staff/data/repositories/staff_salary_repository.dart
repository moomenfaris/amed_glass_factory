import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../models/staff_attendance.dart';
import '../models/staff_plus_hours.dart';
import '../models/staff_salary.dart';

abstract class StaffSalaryRepository {
  Future<StaffSalary> fetch({required int employeeId, DateTime? at});
  Future<double> fetchPlusHours({required int employeeId, DateTime? at});
  Future<StaffPlusHoursDetails> fetchPlusHoursDetails({
    required int employeeId,
    DateTime? at,
  });
  Future<StaffAttendance> fetchAttendance({
    required int employeeId,
    DateTime? at,
  });
}

class ApiStaffSalaryRepository implements StaffSalaryRepository {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _plusHoursEndpoint =
      'https://amed.ideavsion.online:448/api/EmployessSalary/GetEmployessPlusHours';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';

  final Dio _dio;

  ApiStaffSalaryRepository({Dio? dio})
    : _dio =
          dio ??
          (Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                'x-api-key': _apiKey,
                'Content-Type': 'application/json',
              },
              responseType: ResponseType.json,
            ),
          )..interceptors.addAll(_defaultInterceptors()));

  static List<Interceptor> _defaultInterceptors() {
    if (!kDebugMode) return const [];
    return [
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    ];
  }

  @override
  Future<StaffSalary> fetch({required int employeeId, DateTime? at}) async {
    try {
      final dateTime = (at ?? DateTime.now()).toUtc().toIso8601String();
      final res = await _dio.post(
        '/api/EmployessSalary/Get',
        data: {'datE1': dateTime, 'idEmployess': employeeId},
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }
      final body = Map<String, dynamic>.from(data);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب بيانات الراتب',
        );
      }

      final rawData = body['data'];
      if (rawData is! Map) {
        throw const ServerFailure('بيانات الراتب غير متوفرة');
      }

      return StaffSalary.fromApi(Map<String, dynamic>.from(rawData));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات راتب الموظف: $e');
    }
  }

  @override
  Future<double> fetchPlusHours({required int employeeId, DateTime? at}) async {
    try {
      final dateTime = (at ?? DateTime.now()).toUtc().toIso8601String();
      final payload = {'datE1': dateTime, 'idEmployess': employeeId};
      final res = await _dio.post(
        _plusHoursEndpoint,
        data: payload,
        options: Options(
          method: 'POST',
          headers: {'x-api-key': _apiKey, 'Content-Type': 'application/json'},
        ),
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(data);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب الساعات الإضافية',
        );
      }

      final parsed =
          _extractPlusHours(body['totalHours']) ??
          _extractPlusHours(body['data']);
      return parsed ?? 0;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات الساعات الإضافية: $e');
    }
  }

  @override
  Future<StaffPlusHoursDetails> fetchPlusHoursDetails({
    required int employeeId,
    DateTime? at,
  }) async {
    try {
      final dateTime = (at ?? DateTime.now()).toUtc().toIso8601String();
      final payload = {'datE1': dateTime, 'idEmployess': employeeId};
      final res = await _dio.post(
        _plusHoursEndpoint,
        data: payload,
        options: Options(
          method: 'POST',
          headers: {'x-api-key': _apiKey, 'Content-Type': 'application/json'},
        ),
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(data);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب الساعات الإضافية',
        );
      }

      return StaffPlusHoursDetails.fromApi(body);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة تفاصيل الساعات الإضافية: $e');
    }
  }

  @override
  Future<StaffAttendance> fetchAttendance({
    required int employeeId,
    DateTime? at,
  }) async {
    try {
      final dateTime = (at ?? DateTime.now()).toUtc().toIso8601String();
      final res = await _dio.post(
        '/api/EmployessSalary/GetEmployessAttendance',
        data: {'datE1': dateTime, 'idEmployess': employeeId},
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(data);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب بيانات الدوام',
        );
      }

      final rawData = body['data'];
      if (rawData is! List || rawData.isEmpty || rawData.first is! Map) {
        throw const ServerFailure('بيانات الدوام غير متوفرة');
      }

      return StaffAttendance.fromApiRow(
        Map<String, dynamic>.from(rawData.first as Map),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات الدوام: $e');
    }
  }

  double? _extractPlusHours(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    if (value is List && value.isNotEmpty) {
      return _extractPlusHours(value.first);
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final candidates = [
        map['totalHours'],
        map['الساعت_الاضافية'],
        map['الساعات_الاضافية'],
        map['plusHours'],
        map['overtimeHours'],
        map['value'],
      ];
      for (final c in candidates) {
        final p = _extractPlusHours(c);
        if (p != null) return p;
      }
      for (final entry in map.values) {
        final p = _extractPlusHours(entry);
        if (p != null) return p;
      }
    }
    return null;
  }
}
