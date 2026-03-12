import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ResidentProvider extends ChangeNotifier {
  final ApiClient _api;

  List<Map<String, dynamic>> _apartments = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  ResidentProvider(this._api);

  List<Map<String, dynamic>> get apartments => _apartments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadResidents({int? apartmentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = <String, dynamic>{};
    if (apartmentId != null) params['apartment_id'] = apartmentId;

    final response =
        await _api.get('/residents/list.php', queryParams: params);

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final apts = (data['apartments'] as List?)
              ?.map((a) => a as Map<String, dynamic>)
              .toList() ??
          [];

      // Merge top-level pending_approvals into each apartment
      final pendingAll = (data['pending_approvals'] as List?)
              ?.map((p) => p as Map<String, dynamic>)
              .toList() ??
          [];

      for (final apt in apts) {
        final aptId = apt['apartment_id'];
        apt['pending_requests'] = pendingAll
            .where((p) => p['apartment_id'] == aptId)
            .toList();
      }

      _apartments = apts;
    } else {
      _error = response.message ?? 'მცხოვრებლების ჩატვირთვა ვერ მოხერხდა';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> approveRequest(int requestId) async {
    _error = null;
    _successMessage = null;
    notifyListeners();

    final response = await _api.post('/residents/approve.php', data: {
      'request_id': requestId,
    });

    if (response.success) {
      _successMessage = response.message ?? 'მოთხოვნა დადასტურებულია';
      await loadResidents();
      return true;
    } else {
      _error = response.message ?? 'დადასტურება ვერ მოხერხდა';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(int requestId) async {
    _error = null;
    _successMessage = null;
    notifyListeners();

    final response = await _api.post('/residents/reject.php', data: {
      'request_id': requestId,
    });

    if (response.success) {
      _successMessage = response.message ?? 'მოთხოვნა უარყოფილია';
      await loadResidents();
      return true;
    } else {
      _error = response.message ?? 'უარყოფა ვერ მოხერხდა';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeResident(int userId, int apartmentId) async {
    _error = null;
    _successMessage = null;
    notifyListeners();

    final response = await _api.post('/residents/remove.php', data: {
      'user_id': userId,
      'apartment_id': apartmentId,
    });

    if (response.success) {
      _successMessage = response.message ?? 'მომხმარებელი წაიშალა';
      await loadResidents();
      return true;
    } else {
      _error = response.message ?? 'წაშლა ვერ მოხერხდა';
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
