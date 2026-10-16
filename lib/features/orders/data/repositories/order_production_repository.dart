import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../models/order_production.dart';

abstract class OrderProductionRepository {
  Future<List<OrderProductionItem>> fetch(String orderId);
  Future<List<OrderProductionItem>> fetchDone(int codeCom);
  Future<List<OrderProductionItem>> fetchAll();
}

class ApiOrderProductionRepository implements OrderProductionRepository {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';

  final Dio _dio;

  ApiOrderProductionRepository({Dio? dio})
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
  Future<List<OrderProductionItem>> fetch(String orderId) async {
    try {
      final res = await _dio.post(
        '/api/order-production/get',
        data: {'orderId': orderId},
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }
      final body = Map<String, dynamic>.from(data);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب تفاصيل الحركة',
        );
      }
      final raw = (body['data'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map((e) => OrderProductionItem.fromApi(Map<String, dynamic>.from(e)))
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
      throw ServerFailure('تعذر قراءة تفاصيل الحركة: $e');
    }
  }

  @override
  Future<List<OrderProductionItem>> fetchDone(int codeCom) async {
    try {
      final res = await _dio.post(
        '/api/order-production/IsDone',
        data: {'code_com': codeCom},
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }
      final body = Map<String, dynamic>.from(data);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب الحركات المكتملة',
        );
      }
      final raw = (body['data'] as List?) ?? const [];
      final flattened = <OrderProductionItem>[];

      for (final row in raw.whereType<Map>()) {
        final parent = Map<String, dynamic>.from(row);
        final items = (parent['items'] as List?) ?? const [];

        // New API shape: each parent order contains nested `items`.
        if (items.isNotEmpty) {
          for (final item in items.whereType<Map>()) {
            final merged = <String, dynamic>{
              ...Map<String, dynamic>.from(item),
              'رقم_الطلبية': parent['رقم_الطلبية'] ?? parent['رقم الطلبية'],
              'اسم_المشروع': parent['اسم_المشروع'] ?? parent['اسم المشروع'],
            };
            flattened.add(OrderProductionItem.fromApi(merged));
          }
          continue;
        }

        // Backward compatibility: older shape may return flat list directly.
        flattened.add(OrderProductionItem.fromApi(parent));
      }

      return flattened;
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
      throw ServerFailure('تعذر قراءة الحركات المكتملة: $e');
    }
  }

  @override
  Future<List<OrderProductionItem>> fetchAll() async {
    try {
      final res = await _dio.post(
        '/api/order-production/all',
        options: Options(headers: {'x-api-key': _apiKey}),
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }
      final body = Map<String, dynamic>.from(data);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب الحركات المكتملة',
        );
      }

      final raw = (body['data'] as List?) ?? const [];
      final flattened = <OrderProductionItem>[];

      for (final row in raw.whereType<Map>()) {
        final parent = Map<String, dynamic>.from(row);
        final items = (parent['items'] as List?) ?? const [];

        if (items.isNotEmpty) {
          for (final item in items.whereType<Map>()) {
            final merged = <String, dynamic>{
              ...Map<String, dynamic>.from(item),
              'اسم_الزبون': parent['اسم_الزبون'] ?? parent['اسم الزبون'],
              'رقم_الطلبية': parent['رقم_الطلبية'] ?? parent['رقم الطلبية'],
              'اسم_المشروع': parent['اسم_المشروع'] ?? parent['اسم المشروع'],
            };
            flattened.add(OrderProductionItem.fromApi(merged));
          }
          continue;
        }

        flattened.add(OrderProductionItem.fromApi(parent));
      }

      return flattened;
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
      throw ServerFailure('تعذر قراءة الحركات المكتملة: $e');
    }
  }
}
