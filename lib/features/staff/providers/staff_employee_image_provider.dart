import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failures.dart';

final staffEmployeeImageRepositoryProvider =
    Provider<StaffEmployeeImageRepository>(
      (_) => ApiStaffEmployeeImageRepository(),
    );

final staffEmployeeImageProvider = FutureProvider.family<String?, int>((
  ref,
  employeeId,
) {
  return ref
      .watch(staffEmployeeImageRepositoryProvider)
      .fetchEmployeeImageUrl(employeeId);
});

abstract class StaffEmployeeImageRepository {
  Future<String?> fetchEmployeeImageUrl(int employeeId);
}

class ApiStaffEmployeeImageRepository implements StaffEmployeeImageRepository {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';

  final Dio _dio;

  ApiStaffEmployeeImageRepository({Dio? dio})
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
  Future<String?> fetchEmployeeImageUrl(int employeeId) async {
    try {
      final res = await _dio.post(
        '/api/Image/GetEmployessImages',
        data: {'invoiceId': employeeId},
      );

      final raw = res.data;

      // Some endpoints return plain URL string directly.
      if (raw is String) {
        final url = raw.trim();
        return _normalizeUrl(url);
      }

      if (raw is! Map) return null;
      final body = Map<String, dynamic>.from(raw);

      if (body['success'] == false) {
        final msg = body['message']?.toString().trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب صورة الموظف',
        );
      }

      // Expected API shape:
      // {
      //   "success": true,
      //   "images": ["https://..."]
      // }
      final images = body['images'];
      if (images is List) {
        for (final item in images) {
          if (item is String && item.trim().isNotEmpty) {
            return _normalizeUrl(item.trim());
          }
        }
      }

      final candidates = [
        body['data'],
        body['imageUrl'],
        body['image'],
        body['url'],
        body['path'],
      ];

      for (final item in candidates) {
        if (item is String && item.trim().isNotEmpty) {
          return _normalizeUrl(item.trim());
        }
        if (item is Map) {
          final nested = [
            item['imageUrl'],
            item['url'],
            item['path'],
            item['fullPath'],
          ];
          for (final v in nested) {
            if (v is String && v.trim().isNotEmpty) {
              return _normalizeUrl(v.trim());
            }
          }
        }
      }

      return null;
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
      throw ServerFailure('تعذر قراءة رابط صورة الموظف: $e');
    }
  }

  String _normalizeUrl(String input) {
    final value = input.trim();
    if (value.isEmpty) return value;
    if (value.startsWith('https://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) return '$_baseUrl$value';
    return '$_baseUrl/$value';
  }
}
