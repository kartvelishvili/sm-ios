import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api;
  final StorageService _storage;

  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider(this._api, this._storage);

  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Get real device model name
  Future<String> _getDeviceInfo() async {
    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      return '${android.brand} ${android.model}';
    } catch (_) {
      return 'Android Device';
    }
  }

  // --- Initialize (check stored token) ---
  Future<void> initialize() async {
    try {
      final hasToken = await _storage.hasValidToken();
      if (hasToken) {
        final userData = _storage.getUserData();
        if (userData != null) {
          _user = User.fromJson(userData);
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.unauthenticated;
        }
      } else {
        await _storage.clearAll();
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      debugPrint('Initialize error: $e');
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // --- Login ---
  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post('/auth/login.php', data: {
        'email': email,
        'password': password,
        'device_info': await _getDeviceInfo(),
      });

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final expiresAt = data['expires_at'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        await _storage.saveToken(token, expiresAt);
        await _storage.saveUserData(userData);
        _user = User.fromJson(userData);
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'ავტორიზაცია ვერ მოხერხდა';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'დაფიქსირდა შეცდომა. სცადეთ მოგვიანებით.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // --- Register ---
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String personalId,
    required String phone,
    required String email,
    required String password,
    required int complexId,
    int? apartmentId,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _api.post('/auth/register.php', data: {
      'first_name': firstName,
      'last_name': lastName,
      'personal_id': personalId,
      'phone': phone,
      'email': email,
      'password': password,
      'complex_id': complexId,
      if (apartmentId != null) 'apartment_id': apartmentId,
      'device_info': await _getDeviceInfo(),
    });

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'active' && data['token'] != null) {
        await _storage.saveToken(
          data['token'] as String,
          data['expires_at'] as String,
        );
        if (data['user'] != null) {
          await _storage.saveUserData(data['user'] as Map<String, dynamic>);
          _user = User.fromJson(data['user'] as Map<String, dynamic>);
        }
        _state = AuthState.authenticated;
        notifyListeners();
        return {'success': true, 'status': 'active'};
      } else {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return {
          'success': true,
          'status': 'pending_approval',
          'message': data['message'] ?? response.message,
        };
      }
    } else {
      _errorMessage = response.message ?? 'რეგისტრაცია ვერ მოხერხდა';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
        'errors': response.errors,
      };
    }
  }

  // --- Forgot Password ---
  Future<ApiResponse> forgotPasswordRequest(String identifier,
      {String method = 'phone'}) async {
    return await _api.post('/auth/forgot-password.php', data: {
      'action': 'request',
      'method': method,
      'identifier': identifier,
    });
  }

  Future<ApiResponse> forgotPasswordVerify(String phone, String code) async {
    return await _api.post('/auth/forgot-password.php', data: {
      'action': 'verify',
      'phone': phone,
      'code': code,
    });
  }

  Future<ApiResponse> forgotPasswordReset(
      String phone, String code, String newPassword) async {
    return await _api.post('/auth/forgot-password.php', data: {
      'action': 'reset',
      'phone': phone,
      'code': code,
      'new_password': newPassword,
    });
  }

  // --- Get Complexes ---
  Future<List<Complex>> getComplexes() async {
    final response = await _api.get('/auth/register.php',
        queryParams: {'action': 'complexes'});
    if (response.success && response.data != null) {
      return (response.data as List)
          .map((c) => Complex.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // --- Get Apartments ---
  Future<List<Apartment>> getApartments(int complexId) async {
    final response = await _api.get('/auth/register.php',
        queryParams: {'action': 'apartments', 'complex_id': complexId});
    if (response.success && response.data != null) {
      return (response.data as List)
          .map((a) => Apartment.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // --- Logout ---
  Future<void> logout({bool allDevices = false}) async {
    await _api.post('/auth/logout.php', data: {
      'all_devices': allDevices,
    });
    await _storage.clearAll();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Called by ApiClient 401 interceptor — immediate local logout without API call
  void forceLogout() {
    _storage.clearAll();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // --- Refresh Token ---
  Future<bool> refreshToken() async {
    final response = await _api.post('/auth/refresh.php', data: {
      'device_info': await _getDeviceInfo(),
    });
    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      await _storage.saveToken(
        data['token'] as String,
        data['expires_at'] as String,
      );
      return true;
    }
    return false;
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }
}
