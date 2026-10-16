import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_update_service.dart';

enum LocationUpdateStatus {
  idle,
  loading,
  success,
  locationDisabled,
  permissionDenied,
}

class LocationUpdateNotifier extends StateNotifier<LocationUpdateStatus> {
  bool _hasRun = false;
  String? _lastUserId;

  LocationUpdateNotifier() : super(LocationUpdateStatus.idle);

  /// Triggers the location update flow.
  /// Re-runs if a different [userId] is provided (new login session).
  void run(String? userId) {
    if (userId == null) return;
    if (_hasRun && _lastUserId == userId) return;
    _hasRun = true;
    _lastUserId = userId;
    _doUpdate(userId);
  }

  /// Resets state so it runs again on next login (call on logout).
  void reset() {
    _hasRun = false;
    _lastUserId = null;
    state = LocationUpdateStatus.idle;
  }

  Future<void> _doUpdate(String userId) async {
    state = LocationUpdateStatus.loading;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = LocationUpdateStatus.locationDisabled;
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = LocationUpdateStatus.permissionDenied;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final svc = LocationUpdateService();
      final token = await svc.getDeviceToken();
      final id = int.tryParse(userId) ?? 0;

      await svc.sendLocationUpdate(
        userId: id,
        latitude: position.latitude,
        longitude: position.longitude,
        token: token,
      );

      state = LocationUpdateStatus.success;
    } on LocationServiceDisabledException {
      state = LocationUpdateStatus.locationDisabled;
    } catch (_) {
      // Don't block UX for API / GPS errors
      state = LocationUpdateStatus.success;
    }
  }
}

final locationUpdateProvider =
    StateNotifierProvider<LocationUpdateNotifier, LocationUpdateStatus>(
  (ref) => LocationUpdateNotifier(),
);
