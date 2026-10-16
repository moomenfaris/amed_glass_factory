import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../models/employee_warehouse_item.dart';

abstract class EmployeeWarehouseRepository {
  Future<List<EmployeeWarehouseItem>> fetchStock();
}

class ApiEmployeeWarehouseRepository implements EmployeeWarehouseRepository {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';

  final Dio _dio;

  ApiEmployeeWarehouseRepository({Dio? dio})
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
  Future<List<EmployeeWarehouseItem>> fetchStock() async {
    try {
      final res = await _dio.post('/api/GlassStock/Get', data: const {});

      final bodyRaw = res.data;
      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب بيانات المخزن',
        );
      }

      final raw = (body['data'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => EmployeeWarehouseItem.fromApi(Map<String, dynamic>.from(e)),
          )
          .toList();
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
      throw ServerFailure('تعذر قراءة بيانات المخزن: $e');
    }
  }
}
