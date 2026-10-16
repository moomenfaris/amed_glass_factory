import 'package:geolocator/geolocator.dart';

import '../../features/auth/data/models/user.dart';
import 'location_update_service.dart';
import 'login_datetime_service.dart';

class HomeEntryMetadataPayload {
  final String token;
  final String time;
  final String gps;

  const HomeEntryMetadataPayload({
    required this.token,
    required this.time,
    required this.gps,
  });
}

class HomeEntryMetadataService {
  final LocationUpdateService _locationUpdateService;
  final LoginDateTimeService _loginDateTimeService;

  HomeEntryMetadataService({
    LocationUpdateService? locationUpdateService,
    LoginDateTimeService? loginDateTimeService,
  }) : _locationUpdateService =
           locationUpdateService ?? LocationUpdateService(),
       _loginDateTimeService = loginDateTimeService ?? LoginDateTimeService();

  Future<HomeEntryMetadataPayload?> sendForUserOnHomeEnter({
    required User? user,
    required String? authToken,
  }) async {
    if (user == null) return null;

    final role = user.role;
    final id = user.userId ?? int.tryParse(user.id);
    if (id == null || id <= 0) return null;

    final supportedRole =
        role == 'admin' ||
        role == 'customer' ||
        role == 'client' ||
        role == 'employee' ||
        role == 'staff';
    if (!supportedRole) return null;

    final tokenToSend = await _resolveTokenToSend(authToken: authToken);
    if (tokenToSend.isEmpty) return null;

    final now = DateTime.now();
    final position = await _tryGetCurrentPosition();
    final latitude = position?.latitude ?? 0;
    final longitude = position?.longitude ?? 0;

    if (role == 'staff') {
      await _locationUpdateService.sendEmployeeLocationUpdate(
        userId: id,
        latitude: latitude,
        longitude: longitude,
        token: tokenToSend,
      );
      await _loginDateTimeService.sendEmployeeLoginDateTime(
        userId: id,
        at: now,
      );
    } else {
      await _locationUpdateService.sendCompanyTokenUpdate(
        token: tokenToSend,
        userId: id,
        latitude: latitude,
        longitude: longitude,
      );
      await _loginDateTimeService.sendLoginDateTime(userId: id, at: now);
    }

    return HomeEntryMetadataPayload(
      token: tokenToSend,
      time: now.toIso8601String(),
      gps: '$latitude, $longitude',
    );
  }

  Future<String> _resolveTokenToSend({required String? authToken}) async {
    final fallbackAuthToken = authToken?.trim() ?? '';
    if (fallbackAuthToken.isNotEmpty) return fallbackAuthToken;

    try {
      final generated = await _locationUpdateService.getDeviceToken();
      return generated.trim();
    } catch (_) {
      return '';
    }
  }

  Future<Position?> _tryGetCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
