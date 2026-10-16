import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../models/user.dart';

class AuthService {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';

  final Dio _dio;

  AuthService({Dio? dio})
    : _dio =
          dio ??
          (Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
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
      // requestHeader stays off so the x-api-key value is never printed.
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    ];
  }

  static int? _readPositiveInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      final parsed = value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '');
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  static String? _readNonEmptyString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String _resolveRole(Map<String, dynamic> body) {
    final roleId = _readPositiveInt(body, [
      'role',
      'roleId',
      'role_id',
      'flagLogIn',
    ]);
    if (roleId == 1) return 'admin';
    if (roleId == 2) return 'employee';
    if (roleId == 3) return 'staff';

    final roleStr = _readNonEmptyString(body, [
      'roleName',
      'role_name',
      'type',
    ])?.toLowerCase();
    if (roleStr == 'admin') return 'admin';
    if (roleStr == 'employee') return 'employee';
    if (roleStr == 'staff') return 'staff';
    return 'customer';
  }

  Future<({User user, String token})> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/api/login',
        data: {'username': username, 'password': password},
      );

      final data = res.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }
      final body = Map<String, dynamic>.from(data);

      final success = body['success'] == true;
      final message = (body['message'] as String?)?.trim();

      if (!success) {
        throw AuthFailure(
          message?.isNotEmpty == true ? message! : 'بيانات الدخول غير صحيحة',
        );
      }

      final role = _resolveRole(body);
      final userId = _readPositiveInt(body, ['userId', 'codeCom', 'id']);
      if (userId == null) {
        throw const ServerFailure('تعذر تحديد رقم المستخدم من الاستجابة');
      }
      final name = _readNonEmptyString(body, ['name', 'fullName']) ?? username;

      final user = User(
        id: userId.toString(),
        userId: userId,
        username: username,
        fullName: name,
        role: role,
      );
      return (
        user: user,
        token: 'sess-$userId-${DateTime.now().millisecondsSinceEpoch}',
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
    } catch (_) {
      throw const ServerFailure('حدث خطأ غير متوقع');
    }
  }

  /// Returns [UserStateResult.inactive] only when the server explicitly
  /// confirms it. Any transport or parsing problem maps to `unknown` so the
  /// caller can keep the current session.
  Future<UserStateResult> checkUserState({
    required int userId,
    required String userType,
  }) async {
    try {
      final response = await _dio.post(
        '/api/login/CheckUserState',
        data: {'userId': userId, 'type': userType},
      );

      if (response.statusCode != 200) {
        debugPrint('[AUTH] CheckUserState HTTP ${response.statusCode}');
        return UserStateResult.unknown;
      }

      final body = response.data;
      if (body is! Map) {
        debugPrint('[AUTH] CheckUserState invalid response shape');
        return UserStateResult.unknown;
      }

      final map = Map<String, dynamic>.from(body);
      if (map['success'] != true) {
        debugPrint('[AUTH] CheckUserState success=false');
        return UserStateResult.unknown;
      }

      final data = map['data'];
      final rawState = data is Map
          ? data['state']?.toString().trim().toLowerCase()
          : null;

      if (rawState == null || rawState.isEmpty) {
        debugPrint('[AUTH] CheckUserState missing data.state');
        return UserStateResult.unknown;
      }

      debugPrint('[AUTH] CheckUserState state: $rawState');
      if (rawState == 'active') return UserStateResult.active;
      if (rawState == 'inactive') return UserStateResult.inactive;

      debugPrint('[AUTH] CheckUserState unrecognized state, keeping session');
      return UserStateResult.unknown;
    } on DioException catch (e) {
      debugPrint('[AUTH] CheckUserState network error: ${e.type}');
      return UserStateResult.unknown;
    } catch (_) {
      debugPrint('[AUTH] CheckUserState unexpected error');
      return UserStateResult.unknown;
    }
  }
}

enum UserStateResult { active, inactive, unknown }
