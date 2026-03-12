import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiClient _api;

  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  SettingsProvider(this._api);

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // --- Load Profile ---
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.get('/settings/profile.php');

    if (response.success && response.data != null) {
      _profile = response.data as Map<String, dynamic>;
    } else {
      _error = response.message ?? 'პროფილის ჩატვირთვა ვერ მოხერხდა';
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Upload Profile Image ---
  Future<bool> uploadProfileImage(File image) async {
    _error = null;
    _successMessage = null;
    notifyListeners();

    final formData = FormData.fromMap({
      'profile_image': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
    });

    final response = await _api.upload(
      '/settings/profile.php',
      formData: formData,
    );

    if (response.success) {
      _successMessage = response.message ?? 'სურათი განახლებულია';
      await loadProfile();
      return true;
    } else {
      _error = response.message ?? 'სურათის ატვირთვა ვერ მოხერხდა';
      notifyListeners();
      return false;
    }
  }

  // --- Change Phone (Step 1) ---
  Future<ApiResponse> sendPhoneCode(String newPhone) async {
    return await _api.post('/settings/change-phone.php', data: {
      'action': 'send_code',
      'new_phone': newPhone,
    });
  }

  // --- Change Phone (Step 2) ---
  Future<ApiResponse> verifyPhoneCode(String newPhone, String code) async {
    final response = await _api.post('/settings/change-phone.php', data: {
      'action': 'verify',
      'new_phone': newPhone,
      'code': code,
    });

    if (response.success) {
      await loadProfile();
    }
    return response;
  }

  // --- Change Password ---
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _error = null;
    _successMessage = null;
    notifyListeners();

    final response = await _api.post('/settings/change-password.php', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });

    if (response.success) {
      _successMessage = response.message ?? 'პაროლი წარმატებით შეიცვალა';
      notifyListeners();
      return true;
    } else {
      _error = response.message ?? 'პაროლის შეცვლა ვერ მოხერხდა';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
