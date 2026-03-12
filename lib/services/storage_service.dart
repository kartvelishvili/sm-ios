import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;
  bool _initialized = false;

  StorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // --- Token Management ---

  Future<void> saveToken(String token, String expiresAt) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
    await _prefs.setString(AppConstants.tokenExpiryKey, expiresAt);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _prefs.remove(AppConstants.tokenExpiryKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null) return false;

    final expiryStr = _prefs.getString(AppConstants.tokenExpiryKey);
    if (expiryStr == null) return false;

    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return false;

    return DateTime.now().isBefore(expiry);
  }

  // --- User Data ---

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(AppConstants.userKey, jsonEncode(userData));
  }

  Map<String, dynamic>? getUserData() {
    final data = _prefs.getString(AppConstants.userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> deleteUserData() async {
    await _prefs.remove(AppConstants.userKey);
  }

  // --- Clear All ---

  Future<void> clearAll() async {
    await deleteToken();
    await deleteUserData();
  }
}
