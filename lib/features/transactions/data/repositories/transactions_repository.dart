import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_data.dart';
import '../models/transaction.dart';

abstract class TransactionsRepository {
  Future<List<AccountTransaction>> fetchAll();
}

class MockTransactionsRepository implements TransactionsRepository {
  @override
  Future<List<AccountTransaction>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final list = [...MockData.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}

class ApiTransactionsRepository implements TransactionsRepository {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';

  final int codeCom;
  final DateTime? dateTo;
  final Dio _dio;

  ApiTransactionsRepository({required this.codeCom, this.dateTo, Dio? dio})
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

  static String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  @override
  Future<List<AccountTransaction>> fetchAll() async {
    try {
      final res = await _dio.post(
        '/api/movment/get',
        data: {
          'codeCom': codeCom,
          'dateTo': _fmtDate(dateTo ?? DateTime.now()),
        },
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }
      final body = Map<String, dynamic>.from(data);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب الحركات',
        );
      }
      final raw = (body['data'] as List?) ?? const [];
      final list =
          raw
              .whereType<Map>()
              .map(
                (e) => AccountTransaction.fromApi(Map<String, dynamic>.from(e)),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      return list;
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
      throw ServerFailure('تعذر قراءة بيانات الحركات: $e');
    }
  }
}
