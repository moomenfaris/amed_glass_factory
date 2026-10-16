import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class LoginDateTimeService {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';
  static const Duration _baghdadOffset = Duration(hours: 3);
  static const String _employeeLoginDateTimeUrl =
      'https://amed.ideavsion.online:448/api/company/LogInDateTime-Employess';

  final Dio _dio;

  LoginDateTimeService({Dio? dio})
    : _dio =
          dio ??
          Dio(
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
          );

  Future<void> sendLoginDateTime({required int userId, DateTime? at}) async {
    final dateTime = _toBaghdadIso8601(at ?? DateTime.now());
    await _dio.post(
      '/api/company/LogInDateTime',
      data: {'id': userId, 'dateTime1': dateTime},
    );
  }

  Future<void> sendEmployeeLoginDateTime({
    required int userId,
    DateTime? at,
  }) async {
    final dateTime = _toBaghdadIso8601(at ?? DateTime.now());
    await _dio.post(
      _employeeLoginDateTimeUrl,
      data: {'id': userId, 'dateTime1': dateTime},
    );
  }

  String _toBaghdadIso8601(DateTime input) {
    final baghdadTime = input.toUtc().add(_baghdadOffset);
    final formatted = DateFormat(
      "yyyy-MM-dd'T'HH:mm:ss.SSS",
    ).format(baghdadTime);
    return '$formatted+03:00';
  }
}
