import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationUpdateService {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';
  static const String _tokenKey = 'device_push_token';
  static const String _employeeLocationUrl =
      'https://amed.ideavsion.online:448/api/company/update-location-Employess';
  static const String _companyUpdateLocationPath =
      '/api/company/update-location';
  static const String _companyUpdateLocationUrl =
      'https://amed.ideavsion.online:448/api/company/update-location';

  /// Returns a stable device token stored in SharedPreferences.
  /// Generates a random one on first launch.
  Future<String> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(_tokenKey);
    if (token == null) {
      final rng = Random.secure();
      token = List.generate(
        32,
        (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await prefs.setString(_tokenKey, token);
    }
    return token;
  }

  Future<void> sendLocationUpdate({
    required int userId,
    required double latitude,
    required double longitude,
    required String token,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'x-api-key': _apiKey, 'Content-Type': 'application/json'},
      ),
    );
    await dio.post(
      _companyUpdateLocationPath,
      data: {
        'id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'token': token,
      },
    );
  }

  /// Sends payload expected by company update-location endpoint.
  /// Required shape:
  /// {"id":10004,"latitude":0,"longitude":0,"token":"..."}
  Future<void> sendCompanyTokenUpdate({
    required String token,
    int userId = 0,
    double latitude = 0,
    double longitude = 0,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'x-api-key': _apiKey, 'Content-Type': 'application/json'},
      ),
    );

    await dio.post(
      _companyUpdateLocationUrl,
      data: {
        'id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'token': token,
      },
    );
  }

  Future<void> sendEmployeeLocationUpdate({
    required int userId,
    required double latitude,
    required double longitude,
    required String token,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'x-api-key': _apiKey, 'Content-Type': 'application/json'},
      ),
    );

    await dio.post(
      _employeeLocationUrl,
      data: {
        'id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'token': token,
      },
    );
  }

  /// Sends staff token payload expected by employees update-location endpoint.
  /// Required shape:
  /// {"id":0,"latitude":0,"longitude":0,"token":"..."}
  Future<void> sendEmployeeTokenUpdate({required String token}) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'x-api-key': _apiKey, 'Content-Type': 'application/json'},
      ),
    );

    await dio.post(
      _employeeLocationUrl,
      data: {'id': 0, 'latitude': 0, 'longitude': 0, 'token': token},
    );
  }
}
