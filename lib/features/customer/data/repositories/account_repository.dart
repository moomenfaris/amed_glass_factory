import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_data.dart';
import '../models/account_summary.dart';
import '../models/movement_total_item.dart';

abstract class AccountRepository {
  Future<AccountSummary> fetchSummary();
  Future<List<MovementTotalItem>> fetchTotalsRows();
}

class MockAccountRepository implements AccountRepository {
  @override
  Future<AccountSummary> fetchSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockData.accountSummary();
  }

  @override
  Future<List<MovementTotalItem>> fetchTotalsRows() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [];
  }
}

class ApiAccountRepository implements AccountRepository {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';

  final int codeCom;
  final DateTime? dateTo;
  final Dio _dio;

  ApiAccountRepository({required this.codeCom, this.dateTo, Dio? dio})
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

  Future<Response<dynamic>> _postTotals(Map<String, dynamic> payload) {
    return _dio.post('/api/movment/Totals', data: payload);
  }

  static String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static double _asDouble(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return double.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  static double _readNumber(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key)) {
        final value = _asDouble(source[key]);
        if (value != 0) return value;
      }
    }
    for (final key in keys) {
      if (source.containsKey(key)) {
        return _asDouble(source[key]);
      }
    }
    return 0;
  }

  static String _normalizeArabic(String input) {
    return input
        .trim()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا');
  }

  static ({bool found, double net}) _findNetByStatement(
    List<Map<String, dynamic>> rows,
    String statement,
  ) {
    final target = _normalizeArabic(statement);
    for (final row in rows) {
      final name = _normalizeArabic(
        (row['البيان'] ?? row['statement'] ?? '').toString(),
      );
      if (name == target) {
        return (
          found: true,
          net: _asDouble(row['الصافي'] ?? row['net'] ?? row['balance']),
        );
      }
    }
    return (found: false, net: 0);
  }

  Future<List<Map<String, dynamic>>> _fetchRows() async {
    final res = await _postTotals({
      'codeCom': codeCom,
      'dateTo': _fmtDate(dateTo ?? DateTime.now()),
    });

    final raw = res.data;
    if (raw is! Map) {
      throw const ServerFailure('استجابة غير صالحة من الخادم');
    }

    final body = Map<String, dynamic>.from(raw);
    if (body.containsKey('success') && body['success'] != true) {
      final msg = (body['message'] as String?)?.trim();
      throw ServerFailure(
        msg?.isNotEmpty == true ? msg! : 'تعذر جلب ملخص المديونية',
      );
    }

    final data = body['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return const [];
  }

  @override
  Future<List<MovementTotalItem>> fetchTotalsRows() async {
    try {
      final rows = await _fetchRows();
      return rows.map(MovementTotalItem.fromApi).toList();
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
      throw ServerFailure('تعذر قراءة المجاميع: $e');
    }
  }

  @override
  Future<AccountSummary> fetchSummary() async {
    try {
      final rows = await _fetchRows();
      Map<String, dynamic> source = const {};
      if (rows.isNotEmpty) {
        source = Map<String, dynamic>.from(rows.first);
      }

      if (rows.isNotEmpty) {
        final total = _findNetByStatement(rows, 'اجمالي المديونية');
        final executed = _findNetByStatement(rows, 'المديونية المنفذة');
        if (total.found || executed.found) {
          return AccountSummary(
            totalIndebtedness: total.net,
            executedIndebtedness: executed.net,
          );
        }
      }

      final totalIndebtedness = _readNumber(source, [
        'totalIndebtedness',
        'totalDebt',
        'total_debt',
        'debtTotal',
        'مديونية',
        'اجمالي_المديونية',
      ]);

      final executedIndebtedness = _readNumber(source, [
        'executedIndebtedness',
        'executedDebt',
        'paidDebt',
        'doneDebt',
        'debtExecuted',
        'المديونية_المنفذة',
      ]);

      return AccountSummary(
        totalIndebtedness: totalIndebtedness,
        executedIndebtedness: executedIndebtedness,
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
      throw ServerFailure('تعذر قراءة كشف الحساب: $e');
    }
  }
}
