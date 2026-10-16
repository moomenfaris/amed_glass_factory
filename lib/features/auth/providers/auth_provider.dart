import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/location_update_service.dart';
import '../../../core/services/login_datetime_service.dart';
import '../../../core/storage/local_storage.dart';
import '../data/models/user.dart';
import '../data/services/auth_service.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool loading;
  final String? error;

  /// True until the startup session restore + CheckUserState call completes.
  final bool bootstrapping;

  const AuthState({
    this.user,
    this.token,
    this.loading = false,
    this.error,
    this.bootstrapping = false,
  });

  bool get isLoggedIn => user != null && token != null;
  String? get role => user?.role;

  AuthState copyWith({
    User? user,
    String? token,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? bootstrapping,
  }) => AuthState(
    user: user ?? this.user,
    token: token ?? this.token,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    bootstrapping: bootstrapping ?? this.bootstrapping,
  );
}

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((
  ref,
) {
  return AuthController(ref.watch(authServiceProvider))..bootstrap();
});

class AuthController extends StateNotifier<AuthState> {
  final AuthService _service;
  final LocationUpdateService _locationUpdateService = LocationUpdateService();
  final LoginDateTimeService _loginDateTimeService = LoginDateTimeService();
  static const String _localAdminTokenPrefix = 'local-admin-';

  static const Duration _minCheckInterval = Duration(seconds: 30);
  bool _isCheckingUserState = false;
  DateTime? _lastUserStateCheck;

  AuthController(this._service) : super(const AuthState(bootstrapping: true));

  void bootstrap() {
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final token = LocalStorage.getString(LocalStorage.kAuthToken);
    final remember = LocalStorage.getBool(LocalStorage.kRememberMe);
    final raw = LocalStorage.getString('user_json');

    if (token == null || !remember || raw == null) {
      state = state.copyWith(bootstrapping: false);
      return;
    }

    try {
      final user = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (_isLocalAdminSession(token: token, user: user)) {
        state = AuthState(user: user, token: token);
        return;
      }

      final id = user.userId ?? int.tryParse(user.id);
      if (id == null || id <= 0) {
        debugPrint('[AUTH] Stored session has no valid user id');
        await _clearPersistedSession();
        state = state.copyWith(bootstrapping: false);
        return;
      }

      final result = await _runUserStateCheck(user: user, userId: id);
      if (result == UserStateResult.inactive) {
        await forceLogout();
        return;
      }

      state = AuthState(user: user, token: token);
      unawaited(_syncCompanyLoginDateTime(user: user));
      unawaited(_syncCompanyTokenMetadata(user: user, authToken: token));
      unawaited(_syncStaffLoginDateTimeOnAppOpen(user: user));
    } catch (_) {
      debugPrint('[AUTH] Failed to restore stored session');
      await _clearPersistedSession();
      state = state.copyWith(bootstrapping: false);
    }
  }

  /// Re-validates the logged in user, e.g. when the app returns to foreground.
  Future<void> refreshUserState({bool force = false, String? apiType}) async {
    final user = state.user;
    if (user == null || state.bootstrapping) return;
    final token = state.token;
    if (token != null && _isLocalAdminSession(token: token, user: user)) {
      return;
    }

    final id = user.userId ?? int.tryParse(user.id);
    if (id == null || id <= 0) return;

    final last = _lastUserStateCheck;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minCheckInterval) {
      return;
    }

    final result = await _runUserStateCheck(
      user: user,
      userId: id,
      apiType: apiType,
    );
    if (result == UserStateResult.inactive) {
      await forceLogout();
    }
  }

  Future<UserStateResult> _runUserStateCheck({
    required User user,
    required int userId,
    String? apiType,
  }) async {
    if (_isCheckingUserState) return UserStateResult.unknown;
    _isCheckingUserState = true;

    final resolvedType =
        apiType ?? (user.role == 'staff' ? 'employees' : 'company');
    debugPrint('[AUTH] Checking user state...');
    debugPrint('[AUTH] User ID: $userId');
    debugPrint('[AUTH] User Type: ${user.role}');
    debugPrint('[AUTH] API Type: $resolvedType');

    try {
      final result = await _service.checkUserState(
        userId: userId,
        userType: resolvedType,
      );
      _lastUserStateCheck = DateTime.now();

      if (result == UserStateResult.inactive) {
        debugPrint('[AUTH] User is inactive');
      } else if (result == UserStateResult.unknown) {
        debugPrint('[AUTH] CheckUserState inconclusive, keeping session');
      }
      return result;
    } finally {
      _isCheckingUserState = false;
    }
  }

  /// Single place that wipes credentials and drops the authenticated state.
  Future<void> forceLogout() async {
    debugPrint('[AUTH] Performing forced logout');
    await _clearPersistedSession();
    _lastUserStateCheck = null;
    state = const AuthState();
  }

  Future<void> _clearPersistedSession() async {
    debugPrint('[AUTH] Clearing session');
    await LocalStorage.remove(LocalStorage.kAuthToken);
    await LocalStorage.remove(LocalStorage.kUsername);
    await LocalStorage.remove('user_json');
    await LocalStorage.setBool(LocalStorage.kRememberMe, false);
    state = const AuthState();
  }

  Future<void> login({
    required String username,
    required String password,
    required bool remember,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    final localUser = User(
      id: '1',
      userId: 1,
      username: '',
      fullName: '',
      role: 'admin',
    );
    final localToken =
        '$_localAdminTokenPrefix${DateTime.now().millisecondsSinceEpoch}';

    if (remember) {
      await LocalStorage.setString(LocalStorage.kAuthToken, localToken);
      await LocalStorage.setString(LocalStorage.kUsername, username);
      await LocalStorage.setBool(LocalStorage.kRememberMe, true);
      await LocalStorage.setString('user_json', jsonEncode(localUser.toJson()));
    } else {
      await LocalStorage.remove(LocalStorage.kAuthToken);
      await LocalStorage.remove('user_json');
      await LocalStorage.setBool(LocalStorage.kRememberMe, false);
    }

    state = AuthState(user: localUser, token: localToken);
  }

  Future<void> logout() async {
    await forceLogout();
  }

  Future<void> _syncCompanyTokenMetadata({
    required User user,
    required String authToken,
  }) async {
    final role = user.role;
    if (role != 'admin' &&
        role != 'customer' &&
        role != 'client' &&
        role != 'employee') {
      return;
    }

    final id = user.userId ?? int.tryParse(user.id);
    if (id == null || id <= 0) return;

    final tokenToSend = await _resolveAppToken(authToken: authToken);
    if (tokenToSend.trim().isEmpty) return;

    final position = await _tryGetCurrentPosition();
    final latitude = position?.latitude ?? 0;
    final longitude = position?.longitude ?? 0;

    try {
      await _locationUpdateService.sendCompanyTokenUpdate(
        token: tokenToSend,
        userId: id,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      // Metadata sync should never block a successful login.
    }
  }

  Future<void> _syncCompanyLoginDateTime({required User user}) async {
    final role = user.role;
    if (role != 'admin' &&
        role != 'customer' &&
        role != 'client' &&
        role != 'employee') {
      return;
    }

    final id = user.userId ?? int.tryParse(user.id);
    if (id == null || id <= 0) return;

    try {
      await _loginDateTimeService.sendLoginDateTime(userId: id);
    } catch (_) {
      // Metadata sync should never block app startup or a successful login.
    }
  }

  Future<void> _syncStaffLoginDateTimeOnAppOpen({required User user}) async {
    if (user.role != 'staff') return;

    final id = user.userId ?? int.tryParse(user.id);
    if (id == null || id <= 0) return;

    try {
      await _loginDateTimeService.sendEmployeeLoginDateTime(userId: id);
    } catch (_) {
      // Metadata sync should never block app startup.
    }
  }

  Future<String> _resolveAppToken({required String authToken}) async {
    final generated = await _locationUpdateService.getDeviceToken();
    final generatedTrimmed = generated.trim();
    if (generatedTrimmed.isNotEmpty) return generatedTrimmed;

    return authToken.trim();
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

  bool _isLocalAdminSession({required String token, required User user}) {
    return token.startsWith(_localAdminTokenPrefix) && user.role == 'admin';
  }
}
